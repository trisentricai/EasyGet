from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("config", views.SystemConfigViewSet, basename="system-config")
router.register("audit", views.AdminActionViewSet, basename="admin-action")
router.register("banners", views.BannerViewSet, basename="banner")
router.register("coupons", views.CouponViewSet, basename="coupon")
router.register("reviews", views.ProductReviewViewSet, basename="admin-review")
router.register("tasks", views.ScheduledTaskViewSet, basename="scheduled-task")

urlpatterns = [
    path("", include(router.urls)),
    path("dashboard/", views.AdminDashboardViewSet.as_view({"get": "summary"}), name="admin-dashboard"),
]