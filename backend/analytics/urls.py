from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("events", views.UserEventViewSet, basename="user-event")
router.register("metrics", views.DailyMetricsViewSet, basename="daily-metrics")
router.register("funnels", views.FunnelViewSet, basename="funnel")
router.register("retention", views.RetentionViewSet, basename="retention")
router.register("revenue", views.RevenueViewSet, basename="revenue")
router.register("products", views.ProductAnalyticsViewSet, basename="product-analytics")

urlpatterns = [
    path("dashboard/", views.DashboardViewSet.as_view({"get": "summary"}), name="dashboard-summary"),
    path("", include(router.urls)),
]