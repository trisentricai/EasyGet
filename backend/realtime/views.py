from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly, IsAdminOrStoreManager

from .models import ChatMessage, ChatRoom, Device, InventorySubscription
from .serializers import (
    ChatMessageSerializer,
    ChatRoomSerializer,
    DeviceRegisterSerializer,
    DeviceSerializer,
    InventorySubscriptionCreateSerializer,
    InventorySubscriptionSerializer,
)


class DeviceViewSet(viewsets.ModelViewSet):
    """User device management for push notifications."""

    serializer_class = DeviceSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return DeviceRegisterSerializer
        return DeviceSerializer

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"])
    def deactivate(self, request, pk=None):
        device = self.get_object()
        device.is_active = False
        device.save()
        return Response({"status": "deactivated"})


class ChatRoomViewSet(viewsets.ModelViewSet):
    """Chat rooms for support/order discussions."""

    serializer_class = ChatRoomSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ChatRoom.objects.filter(participants=self.request.user).prefetch_related(
            "participants", "messages"
        )

    def get_serializer_class(self):
        if self.action in ["create", "update", "partial_update"]:
            return ChatRoomSerializer
        return ChatRoomSerializer

    def perform_create(self, serializer):
        room = serializer.save()
        room.participants.add(self.request.user)

    @action(detail=True, methods=["post"])
    def add_participant(self, request, pk=None):
        room = self.get_object()
        user_id = request.data.get("user_id")
        if not user_id:
            return Response(
                {"detail": "user_id required"}, status=status.HTTP_400_BAD_REQUEST
            )
        from django.contrib.auth import get_user_model
        User = get_user_model()
        try:
            user = User.objects.get(id=user_id)
            room.participants.add(user)
            return Response({"status": "added"})
        except User.DoesNotExist:
            return Response(
                {"detail": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=["post"])
    def remove_participant(self, request, pk=None):
        room = self.get_object()
        user_id = request.data.get("user_id")
        if not user_id:
            return Response(
                {"detail": "user_id required"}, status=status.HTTP_400_BAD_REQUEST
            )
        from django.contrib.auth import get_user_model
        User = get_user_model()
        try:
            user = User.objects.get(id=user_id)
            room.participants.remove(user)
            return Response({"status": "removed"})
        except User.DoesNotExist:
            return Response(
                {"detail": "User not found"}, status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=["get"])
    def messages(self, request, pk=None):
        room = self.get_object()
        messages = room.messages.select_related("sender", "reply_to").order_by(
            "-created_at"
        )
        page = self.paginate_queryset(messages)
        if page is not None:
            from .serializers import ChatMessageSerializer
            serializer = ChatMessageSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        from .serializers import ChatMessageSerializer
        serializer = ChatMessageSerializer(messages, many=True)
        return Response(serializer.data)


class ChatMessageViewSet(viewsets.ModelViewSet):
    """Chat messages."""

    serializer_class = ChatMessageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ChatMessage.objects.filter(
            room__participants=self.request.user
        ).select_related("sender", "reply_to", "room")

    def get_serializer_class(self):
        if self.action in ["create", "update", "partial_update"]:
            from .serializers import ChatMessageSerializer
            return ChatMessageSerializer
        return ChatMessageSerializer

    def perform_create(self, serializer):
        serializer.save(sender=self.request.user)

    @action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        message = self.get_object()
        if message.sender != request.user:
            message.is_read = True
            message.save(update_fields=["is_read"])
        return Response({"status": "marked_read"})


class InventorySubscriptionViewSet(viewsets.ModelViewSet):
    """Inventory change subscriptions."""

    serializer_class = InventorySubscriptionSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action in ["create", "update", "partial_update"]:
            return InventorySubscriptionCreateSerializer
        return InventorySubscriptionSerializer

    def get_queryset(self):
        return InventorySubscription.objects.filter(user=self.request.user).select_related(
            "product_variant__product"
        )

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)