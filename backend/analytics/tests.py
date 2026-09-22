from datetime import date
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from .models import (
    DailyMetrics,
    FunnelAnalysis,
    FunnelStep,
    ProductPerformance,
    RetentionCohort,
    RevenueByChannel,
    UserEvent,
)

User = get_user_model()


class DailyMetricsTests(TestCase):
    def test_create_metrics(self):
        metrics = DailyMetrics.objects.create(
            date=date(2026, 9, 20),
            new_users=100,
            active_users=500,
            total_orders=50,
            completed_orders=45,
            gmv=Decimal("35000.00"),
            revenue=Decimal("34000.00"),
            refunds=Decimal("500.00"),
        )
        self.assertEqual(metrics.aov, Decimal("700.00"))
        self.assertEqual(metrics.conversion_rate, Decimal("90.00"))
        self.assertEqual(metrics.net_revenue, Decimal("33500.00"))

    def test_zero_orders(self):
        metrics = DailyMetrics.objects.create(date=date(2026, 9, 20), total_orders=0)
        self.assertEqual(metrics.aov, Decimal("0"))
        self.assertEqual(metrics.conversion_rate, Decimal("0"))


class UserEventTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="event@test.com", password="pass")

    def test_create_event(self):
        event = UserEvent.objects.create(
            user=self.user,
            session_id="sess_123",
            event_type=UserEvent.EventType.PRODUCT_VIEW,
            properties={"product_id": "abc", "category": "grocery"},
        )
        self.assertEqual(event.event_type, "PRODUCT_VIEW")
        self.assertEqual(event.properties["product_id"], "abc")

    def test_session_indexing(self):
        UserEvent.objects.create(
            user=self.user,
            session_id="sess_123",
            event_type=UserEvent.EventType.PAGE_VIEW,
        )
        events = UserEvent.objects.filter(session_id="sess_123")
        self.assertEqual(events.count(), 1)


class FunnelTests(TestCase):
    def test_create_funnel_step(self):
        step = FunnelStep.objects.create(
            name="checkout",
            event_type=UserEvent.EventType.CHECKOUT_START,
            order=1,
        )
        self.assertEqual(step.name, "checkout")
        self.assertEqual(step.order, 1)

    def test_funnel_analysis(self):
        analysis = FunnelAnalysis.objects.create(
            funnel_name="checkout",
            date=date(2026, 9, 20),
            step_order=1,
            event_type="CHECKOUT_START",
            entered=100,
            completed=80,
        )
        analysis.save()
        self.assertEqual(analysis.conversion_rate, Decimal("80.00"))


class RetentionTests(TestCase):
    def test_retention_cohort(self):
        cohort = RetentionCohort.objects.create(
            cohort_date=date(2026, 9, 1),
            period=7,
            users_in_cohort=100,
            users_active=35,
        )
        cohort.save()
        self.assertEqual(cohort.retention_rate, Decimal("35.00"))


class RevenueByChannelTests(TestCase):
    def test_revenue_channel(self):
        rc = RevenueByChannel.objects.create(
            date=date(2026, 9, 20),
            channel="organic",
            orders=50,
            revenue=Decimal("25000.00"),
            new_customers=30,
            returning_customers=20,
        )
        self.assertEqual(rc.channel, "organic")


class ProductPerformanceTests(TestCase):
    def test_product_performance(self):
        perf = ProductPerformance.objects.create(
            date=date(2026, 9, 20),
            product_id="123e4567-e89b-12d3-a456-426614174000",
            product_name="Test Product",
            views=1000,
            add_to_carts=100,
            purchases=50,
            revenue=Decimal("35000.00"),
        )
        perf.save()
        self.assertEqual(perf.conversion_rate, Decimal("5.00"))