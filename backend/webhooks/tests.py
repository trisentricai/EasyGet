from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from .models import WebhookDelivery, WebhookEndpoint, WebhookEventLog

User = get_user_model()


class WebhookEndpointTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="webhook@test.com", password="pass")

    def test_create_endpoint(self):
        endpoint = WebhookEndpoint.objects.create(
            name="Order Webhook",
            url="https://example.com/webhook",
            events=[WebhookEndpoint.Event.ORDER_CREATED, WebhookEndpoint.Event.ORDER_CANCELLED],
            secret="secret123",
            created_by=self.user,
        )
        self.assertEqual(endpoint.events, ["ORDER_CREATED", "ORDER_CANCELLED"])
        self.assertTrue(endpoint.matches_event("ORDER_CREATED"))
        self.assertFalse(endpoint.matches_event("PAYMENT_SUCCESS"))

    def test_wildcard_events(self):
        endpoint = WebhookEndpoint.objects.create(
            name="All Events",
            url="https://example.com/all",
            events=["*"],
            created_by=self.user,
        )
        self.assertTrue(endpoint.matches_event("ORDER_CREATED"))
        self.assertTrue(endpoint.matches_event("ANY_EVENT"))

    def test_sign_payload(self):
        endpoint = WebhookEndpoint.objects.create(
            name="Test",
            url="https://example.com",
            events=["ORDER_CREATED"],
            secret="secret123",
            created_by=self.user,
        )
        payload = b'{"order_id": "123"}'
        signature = endpoint.sign_payload(payload)
        self.assertIsInstance(signature, str)
        self.assertEqual(len(signature), 64)  # SHA256 hex


class WebhookDeliveryTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="delivery@test.com", password="pass")
        self.endpoint = WebhookEndpoint.objects.create(
            name="Test Endpoint",
            url="https://example.com/webhook",
            events=["ORDER_CREATED"],
            created_by=self.user,
        )

    def test_create_delivery(self):
        delivery = WebhookDelivery.objects.create(
            endpoint=self.endpoint,
            event="ORDER_CREATED",
            payload={"order_id": "123"},
        )
        self.assertEqual(delivery.status, WebhookDelivery.Status.PENDING)
        self.assertEqual(delivery.attempt, 1)


class WebhookEventLogTests(TestCase):
    def test_create_event_log(self):
        log = WebhookEventLog.objects.create(
            event_type=WebhookEventLog.EventType.ORDER_CREATED,
            payload={"order_id": "123", "total": "100.00"},
        )
        self.assertEqual(log.event_type, "ORDER_CREATED")
        self.assertEqual(log.triggered_webhooks, 0)