from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("endpoints", views.WebhookEndpointViewSet, basename="webhook-endpoint")
router.register("deliveries", views.WebhookDeliveryViewSet, basename="webhook-delivery")
router.register("events", views.WebhookEventLogViewSet, basename="webhook-event")

urlpatterns = [
    path("", include(router.urls)),
]