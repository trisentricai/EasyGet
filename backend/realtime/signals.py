import logging
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.utils import timezone

from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync

from orders.models import Order, OrderStatusHistory
from inventory.models import StockItem
from products.models import ProductVariant
from .models import InventorySubscription

logger = logging.getLogger(__name__)


def _group_send(group: str, event: dict) -> None:
    """Push to a channel group, degrading softly when the layer is broken.

    Local dev often has no (or an incompatible) Redis; a realtime push must
    never take down the request that triggered it (same policy as the
    fail-soft cache in settings.base).
    """
    channel_layer = get_channel_layer()
    if not channel_layer:
        return
    try:
        async_to_sync(channel_layer.group_send)(group, event)
    except Exception:  # noqa: BLE001 - realtime is best-effort
        logger.warning("Realtime push to %s failed (channel layer unavailable)", group)


def send_notification(user_id, message):
    """Send notification to user's WebSocket group."""
    _group_send(
        f"notifications_{user_id}",
        {"type": "notification_message", "message": message},
    )


def send_order_update(user_id, order_id, message):
    """Send order update to user's order tracking group."""
    _group_send(
        f"orders_{user_id}",
        {"type": "order_update", "message": message},
    )
    # Also send to specific order room
    _group_send(
        f"order_{order_id}",
        {"type": "order_update", "message": message},
    )


def send_inventory_update(store_id, message):
    """Send inventory update to store managers."""
    _group_send(
        f"inventory_{store_id}",
        {"type": "inventory_update", "message": message},
    )


def send_chat_message(room_id, message):
    """Send chat message to room."""
    _group_send(
        f"chat_room_{room_id}",
        {"type": "chat_message", "message": message},
    )


@receiver(post_save, sender=Order)
def order_created(sender, instance, created, **kwargs):
    """Notify user when order is created."""
    if created:
        message = {
            "type": "order_created",
            "order_id": str(instance.id),
            "order_number": instance.order_number,
            "status": instance.status,
            "total": str(instance.total),
            "timestamp": timezone.now().isoformat(),
        }
        send_notification(instance.user_id, {
            "type": "order_created",
            "title": "Order Placed",
            "body": f"Your order {instance.order_number} has been placed.",
            "data": {"order_id": str(instance.id)},
            "priority": "HIGH",
        })


@receiver(post_save, sender=OrderStatusHistory)
def order_status_changed(sender, instance, created, **kwargs):
    """Notify user when order status changes."""
    if created:
        order = instance.order
        message = {
            "type": "order_status_changed",
            "order_id": str(order.id),
            "order_number": order.order_number,
            "from_status": instance.from_status,
            "to_status": instance.to_status,
            "note": instance.note,
            "timestamp": instance.created_at.isoformat(),
        }
        send_notification(order.user_id, {
            "type": "order_status_changed",
            "title": f"Order {order.order_number} Updated",
            "body": f"Your order status changed from {instance.from_status} to {instance.to_status}.",
            "data": {"order_id": str(order.id)},
            "priority": "HIGH",
        })
        send_order_update(order.user_id, order.id, {
            "type": "order_status_changed",
            "order_id": str(order.id),
            "from_status": instance.from_status,
            "to_status": instance.to_status,
            "timestamp": instance.created_at.isoformat(),
        })


@receiver(post_save, sender=StockItem)
def stock_changed(sender, instance, created, **kwargs):
    """Notify on stock changes."""
    if not created:
        # Check for low stock/out of stock
        if instance.quantity <= 0:
            trigger = "OUT_OF_STOCK"
        elif instance.quantity <= instance.low_stock_threshold:
            trigger = "LOW_STOCK"
        else:
            trigger = "RESTOCK"

        # Notify subscribed users
        from realtime.models import InventorySubscription
        subscriptions = InventorySubscription.objects.filter(
            product_variant=instance.variant,
            trigger=trigger,
            is_active=True,
        ).select_related("user")

        for sub in subscriptions:
            message = {
                "type": "inventory_alert",
                "variant_id": str(instance.variant.id),
                "variant_sku": instance.variant.sku,
                "store": instance.store.name,
                "quantity": instance.quantity,
                "trigger": trigger,
                "threshold": instance.low_stock_threshold,
                "timestamp": timezone.now().isoformat(),
            }
            send_notification(sub.user_id, {
                "type": "inventory_alert",
                "title": f"Inventory Alert: {trigger.replace('_', ' ').title()}",
                "body": f"{instance.variant.sku} at {instance.store.name}: {instance.quantity} units remaining.",
                "data": {
                    "variant_id": str(instance.variant.id),
                    "store_id": str(instance.store.id),
                    "quantity": instance.quantity,
                },
                "priority": "HIGH" if trigger == "OUT_OF_STOCK" else "NORMAL",
            })

        # Wake the store's realtime group (owners/members watch it per store).
        send_inventory_update(instance.store_id, {
            "type": "stock_changed",
            "variant_id": str(instance.variant.id),
            "variant_sku": instance.variant.sku,
            "quantity": instance.quantity,
            "trigger": trigger,
            "timestamp": timezone.now().isoformat(),
        })


@receiver(post_save, sender=ProductVariant)
def product_variant_changed(sender, instance, created, **kwargs):
    """Notify on price changes."""
    if not created:
        # Check for price change (simplified - would need price tracking in production)
        from realtime.models import InventorySubscription
        subscriptions = InventorySubscription.objects.filter(
            product_variant=instance,
            trigger="PRICE_CHANGE",
            is_active=True,
        ).select_related("user")

        for sub in subscriptions:
            message = {
                "type": "price_change",
                "variant_id": str(instance.id),
                "variant_sku": instance.sku,
                "new_price": str(instance.price),
                "timestamp": timezone.now().isoformat(),
            }
            send_notification(sub.user_id, {
                "type": "price_change",
                "title": "Price Changed",
                "body": f"{instance.sku} price updated to {instance.price}",
                "data": {
                    "variant_id": str(instance.id),
                    "new_price": str(instance.price),
                },
                "priority": "NORMAL",
            })