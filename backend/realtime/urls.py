from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("devices", views.DeviceViewSet, basename="device")
router.register("rooms", views.ChatRoomViewSet, basename="chat-room")
router.register("messages", views.ChatMessageViewSet, basename="chat-message")
router.register("inventory-subscriptions", views.InventorySubscriptionViewSet, basename="inventory-subscription")

urlpatterns = [
    path("", include(router.urls)),
]