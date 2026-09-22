from decimal import Decimal
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from .models import AdminAction, Banner, Coupon, ScheduledTask, SystemConfig

User = get_user_model()


class SystemConfigTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="config@test.com", password="pass")

    def test_create_config(self):
        config = SystemConfig.objects.create(
            key="site_name",
            value="EasyGet",
            config_type=SystemConfig.ConfigType.STRING,
            description="Site name",
            is_public=True,
        )
        self.assertEqual(config.get_typed_value(), "EasyGet")

    def test_typed_values(self):
        configs = [
            ("int_val", "42", SystemConfig.ConfigType.INTEGER, 42),
            ("dec_val", "3.14", SystemConfig.ConfigType.DECIMAL, Decimal("3.14")),
            ("bool_val", "true", SystemConfig.ConfigType.BOOLEAN, True),
            ('json_val', '{"a": 1}', SystemConfig.ConfigType.JSON, {"a": 1}),
        ]
        for key, val, ctype, expected in configs:
            config = SystemConfig.objects.create(
                key=key, value=val, config_type=ctype
            )
            self.assertEqual(config.get_typed_value(), expected)


class BannerTests(TestCase):
    def test_create_banner(self):
        banner = Banner.objects.create(
            title="Summer Sale",
            subtitle="Up to 50% off",
            image="banners/summer.jpg",
            link_url="/sale",
            link_text="Shop Now",
            type=Banner.BannerType.CAROUSEL,
            position=1,
        )
        self.assertTrue(banner.is_valid())
        self.assertEqual(str(banner), "Summer Sale")


class CouponTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="coupon@test.com", password="pass")

    def test_percentage_coupon(self):
        coupon = Coupon.objects.create(
            code="SAVE20",
            name="20% Off",
            discount_type=Coupon.DiscountType.PERCENTAGE,
            discount_value=20,
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=30),
        )
        valid, _ = coupon.is_valid(order_value=Decimal("1000"))
        self.assertTrue(valid)

    def test_fixed_coupon(self):
        coupon = Coupon.objects.create(
            code="SAVE100",
            name="Save 100",
            discount_type=Coupon.DiscountType.FIXED,
            discount_value=100,
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=30),
        )
        valid, _ = coupon.is_valid(order_value=Decimal("500"))
        self.assertTrue(valid)

    def test_coupon_expired(self):
        coupon = Coupon.objects.create(
            code="OLD",
            name="Expired",
            discount_type=Coupon.DiscountType.FIXED,
            discount_value=50,
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=1),
        )
        valid, _ = coupon.is_valid()
        self.assertFalse(valid)


class ScheduledTaskTests(TestCase):
    def test_create_task(self):
        task = ScheduledTask.objects.create(
            name="Daily Report",
            task_type=ScheduledTask.TaskType.CELERY_TASK,
            target="analytics.tasks.generate_daily_report",
            schedule="0 0 * * *",
        )
        self.assertEqual(task.status, ScheduledTask.Status.PENDING)
        self.assertEqual(task.task_type, "CELERY_TASK")