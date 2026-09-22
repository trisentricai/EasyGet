import json
import logging
from django.db.models import Count
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly

from .models import WebhookDelivery, WebhookEndpoint, WebhookEventLog
from .serializers import WebhookDeliverySerializer, WebhookEndpointSerializer, WebhookEventLogSerializer, WebhookTestSerializer


logger = logging.getLogger(__name__)


class WebhookEndpointViewSet(viewsets.ModelViewSet):
    """Webhook endpoint management."""

    queryset = WebhookEndpoint.objects.all()
    serializer_class = WebhookEndpointSerializer
    permission_classes = [IsAdminOnly]

    def get_queryset(self):
        return WebhookEndpoint.objects.filter(created_by=self.request.user)

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=["post"])
    def test(self, request, pk=None):
        endpoint = self.get_object()
        serializer = WebhookTestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from .tasks import deliver_webhook
        event = serializer.validated_data["event"]
        payload = serializer.validated_data["payload"]

        # Trigger delivery asynchronously
        deliver_webhook.delay(str(endpoint.id), event, payload)

        return Response({"status": "test_queued", "event": event})

    @action(detail=True, methods=["get"])
    def deliveries(self, request, pk=None):
        endpoint = self.get_object()
        deliveries = endpoint.deliveries.order_by("-created_at")[:50]
        from .serializers import WebhookDeliverySerializer
        serializer = WebhookDeliverySerializer(deliveries, many=True)
        return Response(serializer.data)


class WebhookDeliveryViewSet(viewsets.ReadOnlyModelViewSet):
    """Webhook delivery logs."""

    queryset = WebhookDelivery.objects.select_related("endpoint")
    serializer_class = WebhookDeliverySerializer
    permission_classes = [IsAdminOnly]

    def get_queryset(self):
        return WebhookDelivery.objects.filter(endpoint__created_by=self.request.user)

    @action(detail=True, methods=["post"])
    def retry(self, request, pk=None):
        delivery = self.get_object()
        if delivery.status == WebhookDelivery.Status.SUCCESS:
            return Response({"error": "Already successful"}, status=400)

        from .tasks import deliver_webhook
        deliver_webhook.delay(str(delivery.endpoint_id), delivery.event, delivery.payload)
        return Response({"status": "retry_queued"})


class WebhookEventLogViewSet(viewsets.ReadOnlyModelViewSet):
    """Event log for debugging."""

    queryset = WebhookEventLog.objects.all()
    serializer_class = WebhookEventLogSerializer
    permission_classes = [IsAdminOnly]

    def get_queryset(self):
        qs = WebhookEventLog.objects.all()
        event_type = self.request.query_params.get("event_type")
        if event_type:
            qs = qs.filter(event_type=event_type)
        days = self.request.query_params.get("days")
        if days:
            from django.utils import timezone
            from datetime import timedelta
            qs = qs.filter(created_at__gte=timezone.now() - timezone.timedelta(days=int(days)))
        return qs

    @action(detail=False, methods=["get"])
    def stats(self, request):
        from django.utils import timezone
        from datetime import timedelta

        days = int(request.query_params.get("days", 7))
        since = timezone.now() - timedelta(days=days)

        stats = WebhookEventLog.objects.filter(created_at__gte=since).values("event_type").annotate(
            count=Count("id")
        ).order_by("-count")

        return Response({
            "period_days": days,
            "total_events": WebhookEventLog.objects.filter(created_at__gte=since).count(),
            "by_event": list(stats),
        })