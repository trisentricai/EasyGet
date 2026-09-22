from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("methods", views.PaymentMethodViewSet, basename="payment-method")
router.register("", views.PaymentViewSet, basename="payment")
router.register("refunds", views.RefundViewSet, basename="refund")

urlpatterns = [
    path("", include(router.urls)),
]