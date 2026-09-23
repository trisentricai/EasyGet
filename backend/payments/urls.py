from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("methods", views.PaymentMethodViewSet, basename="payment-method")
# "refunds" must come before "" — the empty-prefix detail route would
# otherwise swallow /refunds/ as a payment id lookup (404).
router.register("refunds", views.RefundViewSet, basename="refund")
router.register("", views.PaymentViewSet, basename="payment")

urlpatterns = [
    path("", include(router.urls)),
]