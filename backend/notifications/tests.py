from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from .models import Notification, NotificationPreference, NotificationTemplate

User = get_user_model()


class NotificationTemplateTests(TestCase):
    def test_create_template(self):
        template = NotificationTemplate.objects.create(
            name="order_placed_email",
            channel=NotificationTemplate.Channel.EMAIL,
            subject_template="Order {{ order_number }} confirmed",
            body_template="Hi {{ user_name }}, your order {{ order_number }} is confirmed.",
        )
        self.assertEqual(template.channel, "EMAIL")
        self.assertTrue(template.is_active)

    def test_render_template(self):
        template = NotificationTemplate.objects.create(
            name="test",
            channel=NotificationTemplate.Channel.EMAIL,
            subject_template="Hello {{ name }}",
            body_template="Welcome {{ name }}, your code is {{ code }}.",
        )
        subject, body = template.render({"name": "John", "code": "1234"})
        self.assertEqual(subject, "Hello John")
        self.assertEqual(body, "Welcome John, your code is 1234.")


class NotificationTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="notif@test.com", password="pass")

    def test_create_notification(self):
        n = Notification.objects.create(
            user=self.user,
            channel=Notification.Channel.IN_APP,
            subject="Test",
            body="Hello",
        )
        self.assertEqual(n.status, Notification.Status.PENDING)

    def test_mark_sent(self):
        n = Notification.objects.create(
            user=self.user,
            channel=Notification.Channel.EMAIL,
            subject="Test",
            body="Hello",
        )
        n.mark_sent()
        self.assertEqual(n.status, Notification.Status.SENT)
        self.assertIsNotNone(n.sent_at)

    def test_mark_read(self):
        n = Notification.objects.create(
            user=self.user,
            channel=Notification.Channel.IN_APP,
            subject="Test",
            body="Hello",
            status=Notification.Status.SENT,
        )
        n.mark_read()
        self.assertEqual(n.status, Notification.Status.READ)
        self.assertIsNotNone(n.read_at)


class NotificationPreferenceTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="pref@test.com", password="pass")

    def test_create_preference(self):
        pref = NotificationPreference.objects.create(
            user=self.user,
            event_type=NotificationPreference.EventType.ORDER_PLACED,
            channel=NotificationPreference.Channel.EMAIL,
            is_enabled=True,
        )
        self.assertTrue(pref.is_enabled)

    def test_unique_together(self):
        NotificationPreference.objects.create(
            user=self.user,
            event_type=NotificationPreference.EventType.ORDER_PLACED,
            channel=NotificationPreference.Channel.EMAIL,
        )
        with self.assertRaises(Exception):
            NotificationPreference.objects.create(
                user=self.user,
                event_type=NotificationPreference.EventType.ORDER_PLACED,
                channel=NotificationPreference.Channel.EMAIL,
            )

    def test_default_enabled(self):
        pref = NotificationPreference.objects.create(
            user=self.user,
            event_type=NotificationPreference.EventType.ORDER_CANCELLED,
            channel=NotificationPreference.Channel.SMS,
        )
        self.assertTrue(pref.is_enabled)