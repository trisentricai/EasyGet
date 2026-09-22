from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly

from .models import Notification, NotificationPreference, NotificationTemplate
from .serializers import (
    NotificationListSerializer,
    NotificationPreferenceSerializer,
    NotificationSerializer,
    NotificationSendSerializer,
    NotificationTemplateSerializer,
)


class NotificationTemplateViewSet(viewsets.ModelViewSet):
    """Admin-only template management."""

    queryset = NotificationTemplate.objects.all()
    serializer_class = NotificationTemplateSerializer
    permission_classes = [IsAdminOnly]
    filterset_fields = ["channel", "is_active"]
    search_fields = ["name"]


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    """User notifications."""

    serializer_class = NotificationSerializer

    def get_permissions(self):
        return [IsAuthenticated()]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    def get_serializer_class(self):
        if self.action == "list":
            return NotificationListSerializer
        return NotificationSerializer

    @action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.mark_read()
        return Response(NotificationSerializer(notification).data)

    @action(detail=False, methods=["post"])
    def mark_all_read(self, request):
        updated = Notification.objects.filter(
            user=request.user, status__in=[Notification.Status.SENT, Notification.Status.DELIVERED]
        ).update(status=Notification.Status.READ, read_at=timezone.now())
        return Response({"marked_read": updated})

    @action(detail=False, methods=["get"])
    def unread_count(self, request):
        count = Notification.objects.filter(
            user=request.user, status__in=[Notification.Status.SENT, Notification.Status.DELIVERED]
        ).count()
        return Response({"unread_count": count})


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    """User notification preferences."""

    serializer_class = NotificationPreferenceSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return NotificationPreference.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=["get"])
    def all_preferences(self, request):
        """Get all preferences for current user, grouped by event type."""
        prefs = self.get_queryset().select_related("user")
        data = {}
        for pref in prefs:
            if pref.event_type not in data:
                data[pref.event_type] = {}
            data[pref.event_type][pref.channel] = pref.is_enabled
        return Response(data)

    @action(detail=False, methods=["post"])
    def bulk_update(self, request):
        """Update multiple preferences at once."""
        updates = request.data.get("preferences", [])
        for pref_data in updates:
            pref, _ = NotificationPreference.objects.get_or_create(
                user=request.user,
                event_type=pref_data["event_type"],
                channel=pref_data["channel"],
            )
            pref.is_enabled = pref_data["is_enabled"]
            pref.save()
        return Response({"updated": len(updates)})


class NotificationAdminViewSet(viewsets.ModelViewSet):
    """Admin: send notifications, view all."""

    queryset = Notification.objects.all()
    permission_classes = [IsAdminOnly]

    def get_serializer_class(self):
        if self.action == "send":
            return NotificationSendSerializer
        return NotificationSerializer

    def get_serializer_context(self):
        return {"request": self.request}

    @action(detail=False, methods=["post"])
    def send(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        from django.contrib.auth import get_user_model
        User = get_user_model()

        users = User.objects.filter(id__in=data["user_ids"])
        notifications = []
        for user in users:
            n = Notification.objects.create(
                user=user,
                channel=data["channel"],
                subject=data["subject"],
                body=data["body"],
                priority=data["priority"],
                data=data.get("data", {}),
            )
            notifications.append(n)

        # In production, queue for async delivery
        for n in notifications:
            n.mark_sent()

        return Response(
            {"sent": len(notifications), "ids": [str(n.id) for n in notifications]},
            status=status.HTTP_201_CREATED,
        )