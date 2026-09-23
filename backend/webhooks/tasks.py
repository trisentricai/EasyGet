import json
import logging
from celery import shared_task
from django.utils import timezone
import requests

from .models import WebhookDelivery, WebhookEndpoint, WebhookEventLog

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def deliver_webhook(self, endpoint_id, event, payload):
    """Deliver webhook with retries."""
    try:
        endpoint = WebhookEndpoint.objects.get(id=endpoint_id)
    except WebhookEndpoint.DoesNotExist:
        logger.error(f"Endpoint {endpoint_id} not found")
        return

    if not endpoint.is_active or not endpoint.matches_event(event):
        logger.info(f"Endpoint {endpoint_id} inactive or event not matched")
        return

    # Create delivery record
    delivery = WebhookDelivery.objects.create(
        endpoint=endpoint,
        event=event,
        payload=payload,
        attempt=self.request.retries + 1,
    )

    # Prepare request
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "EasyGet-Webhook/1.0",
        **endpoint.headers,
    }

    if endpoint.secret:
        import hmac
        import hashlib
        signature = hmac.new(
            endpoint.secret.encode(),
            json.dumps(payload, separators=(",", ":")).encode(),
            hashlib.sha256
        ).hexdigest()
        headers["X-Webhook-Signature"] = signature

    headers["X-Webhook-Event"] = event
    headers["X-Webhook-Delivery"] = str(delivery.id)

    try:
        response = requests.post(
            endpoint.url,
            json=payload,
            headers=headers,
            timeout=endpoint.timeout_seconds,
        )

        delivery.sent_at = timezone.now()
        delivery.response_status = response.status_code
        delivery.response_body = response.text[:1000]

        if 200 <= response.status_code < 300:
            delivery.status = WebhookDelivery.Status.SUCCESS
            delivery.completed_at = timezone.now()
            logger.info(f"Webhook delivered: {delivery.id} to {endpoint.url}")
        else:
            delivery.status = WebhookDelivery.Status.FAILED
            delivery.error = f"HTTP {response.status_code}: {response.text[:500]}"
            logger.warning(f"Webhook failed: {delivery.id} - {response.status_code}")

    except requests.exceptions.Timeout:
        delivery.status = WebhookDelivery.Status.FAILED
        delivery.error = f"Timeout after {endpoint.timeout_seconds}s"
        logger.warning(f"Webhook timeout: {delivery.id}")
    except requests.exceptions.RequestException as e:
        delivery.status = WebhookDelivery.Status.FAILED
        delivery.error = str(e)
        logger.warning(f"Webhook error: {delivery.id} - {e}")

    delivery.save()

    # Retry logic
    if delivery.status == WebhookDelivery.Status.FAILED:
        if delivery.attempt < endpoint.retry_count:
            delivery.status = WebhookDelivery.Status.RETRYING
            delivery.save()
            # Retry with exponential backoff
            delay = 60 * (2 ** (delivery.attempt - 1))
            self.retry(countdown=delay, exc=Exception(delivery.error))
        else:
            logger.error(f"Webhook max retries exceeded: {delivery.id}")

    # Update endpoint stats
    WebhookEndpoint.objects.filter(id=endpoint.id).update(
        last_delivery_at=timezone.now()
    )


def emit_webhook_event(event_type, payload):
    """Emit an event and trigger matching webhooks."""
    from .models import WebhookEndpoint, WebhookEventLog

    # Log event
    event_log = WebhookEventLog.objects.create(
        event_type=event_type,
        payload=payload,
    )

    # Find matching endpoints
    endpoints = WebhookEndpoint.objects.filter(
        is_active=True
    ).filter(
        models.Q(events__contains=[event_type]) | models.Q(events__contains=["*"])
    )

    triggered = 0
    for endpoint in endpoints:
        from .tasks import deliver_webhook
        deliver_webhook.delay(str(endpoint.id), event_type, payload)
        triggered += 1

    event_log.triggered_webhooks = triggered
    event_log.save(update_fields=["triggered_webhooks"])

    return triggered


# Convenience functions for common events
def emit_order_created(order):
    emit_webhook_event("ORDER_CREATED", {
        "order_id": str(order.id),
        "order_number": order.order_number,
        "user_id": str(order.user_id),
        "total": str(order.total),
        "items": [
            {
                "product": item.product_name,
                "quantity": item.quantity,
                "price": str(item.unit_price),
            }
            for item in order.items.all()
        ],
    })


def emit_order_status_changed(order, from_status, to_status):
    emit_webhook_event("ORDER_STATUS_CHANGED", {
        "order_id": str(order.id),
        "order_number": order.order_number,
        "from_status": from_status,
        "to_status": to_status,
    })


def emit_payment_success(payment):
    emit_webhook_event("PAYMENT_SUCCESS", {
        "payment_id": str(payment.id),
        "order_id": str(payment.order_id),
        "amount": str(payment.amount),
        "gateway": payment.gateway,
    })


def emit_inventory_low(stock_item):
    emit_webhook_event("INVENTORY_LOW", {
        "variant_id": str(stock_item.variant_id),
        "store_id": str(stock_item.store_id),
        "quantity": stock_item.quantity,
        "threshold": stock_item.low_stock_threshold,
    })


def emit_user_registered(user):
    emit_webhook_event("USER_REGISTERED", {
        "user_id": str(user.id),
        "email": user.email,
        "phone": user.phone,
    })