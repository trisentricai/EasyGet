from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from .models import AppUpdate, OfflineData, PWAConfigModel, PushSubscription

User = get_user_model()


class PWAConfigTests(TestCase):
    def test_create_config(self):
        config = PWAConfigModel.objects.create(
            name="Test App",
            short_name="TestApp",
            theme_color="#ff0000",
        )
        manifest = config.get_manifest()
        self.assertEqual(manifest["name"], "Test App")
        self.assertEqual(manifest["theme_color"], "#ff0000")
        self.assertIn("icons", manifest)

    def test_default_icons(self):
        config = PWAConfigModel.objects.create()
        manifest = config.get_manifest()
        self.assertTrue(len(manifest["icons"]) >= 5)


class PushSubscriptionTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="push@test.com", password="pass")

    def test_create_subscription(self):
        sub = PushSubscription.objects.create(
            user=self.user,
            endpoint="https://fcm.googleapis.com/fcm/send/abc123",
            p256dh="p256dh_key",
            auth="auth_key",
        )
        self.assertEqual(sub.get_subscription_info()["endpoint"], "https://fcm.googleapis.com/fcm/send/abc123")
        self.assertTrue(sub.is_active)


class OfflineDataTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="offline@test.com", password="pass")

    def test_store_offline_data(self):
        data = OfflineData.objects.create(
            user=self.user,
            data_type=OfflineData.DataType.CART,
            key="cart_123",
            data={"items": [{"product_id": "1", "qty": 2}]},
            expires_at=timezone.now() + timezone.timedelta(days=7),
        )
        self.assertFalse(data.is_expired())
        self.assertEqual(data.data["items"][0]["qty"], 2)

    def test_expired_data(self):
        data = OfflineData.objects.create(
            user=self.user,
            data_type=OfflineData.DataType.PRODUCTS,
            key="products_list",
            data={"products": []},
            expires_at=timezone.now() - timezone.timedelta(hours=1),
        )
        self.assertTrue(data.is_expired())


class AppUpdateTests(TestCase):
    def test_create_update(self):
        update = AppUpdate.objects.create(
            version="1.2.0",
            platform=AppUpdate.Platform.ANDROID,
            release_notes="Bug fixes and improvements",
            download_url="https://example.com/app.apk",
            is_mandatory=False,
            status=AppUpdate.Status.DEPLOYED,
        )
        self.assertEqual(update.platform, "ANDROID")
        self.assertFalse(update.is_mandatory)