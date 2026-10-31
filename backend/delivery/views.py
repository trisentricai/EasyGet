from django.core.exceptions import ValidationError
from django.db import transaction
from django.db.models import Q
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from tenants.permissions import IsTenantWriter
from tenants.services import is_tenant_member, user_tenant_ids
from users.permissions import IsAdminOnly

from .models import DeliveryAssignment
from .serializers import (
    DeliveryAssignSerializer,
    DeliveryAssignmentSerializer,
    DeliveryStatusUpdateSerializer,
)


def _scoped_delivery_qs(user):
    """Staff see all; tenant members see their tenants'; agents see their own;
    customers see assignments for their own orders."""
    qs = DeliveryAssignment.objects.select_related(
        "order", "order__store", "agent", "tenant"
    )
    if user.is_staff:
        return qs
    tenant_ids = user_tenant_ids(user)
    filt = Q(agent=user) | Q(order__user=user)
    if tenant_ids:
        filt = filt | Q(tenant_id__in=tenant_ids)
    return qs.filter(filt).distinct()


class DeliveryAssignmentViewSet(viewsets.ModelViewSet):
    """Delivery API (manual-assignment v1).
    GET /api/v1/delivery/ — scoped assignment list (staff/all, merchant/tenant,
      agent/own, customer/own orders)
    POST /api/v1/delivery/assign/ — staff or tenant member assigns an agent
    POST /api/v1/delivery/{id}/advance/ — agent, tenant member or staff moves
      the assignment along its state machine (mirrors order status)
    """

    serializer_class = DeliveryAssignmentSerializer
    lookup_field = "id"

    def get_permissions(self):
        if self.action == "assign":
            return [IsAuthenticated(), IsTenantWriter()]
        if self.action in {"list", "retrieve", "advance"}:
            return [IsAuthenticated()]
        # Raw create/update/destroy would accept arbitrary order/agent PKs with
        # no tenant check — assignment writes go through assign/advance only.
        return [IsAdminOnly()]

    def get_queryset(self):
        return _scoped_delivery_qs(self.request.user)

    @action(detail=False, methods=["post"], url_path="assign")
    def assign(self, request):
        serializer = DeliveryAssignSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        order = serializer.validated_data["order"]
        agent = serializer.validated_data["agent"]

        # Staff may assign anything; merchants only their own tenant's orders.
        order_tenant = order.tenant or (
            order.store.tenant if order.store else None
        )
        if not is_tenant_member(request.user, order_tenant):
            return Response(
                {"detail": "Order not found."}, status=status.HTTP_404_NOT_FOUND
            )

        with transaction.atomic():
            assignment = DeliveryAssignment.objects.create(
                order=order,
                tenant=order_tenant,
                agent=agent,
                assigned_by=request.user,
                note=serializer.validated_data.get("note", ""),
            )
        return Response(
            DeliveryAssignmentSerializer(assignment).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"])
    def advance(self, request, id=None):
        try:
            assignment = (
                DeliveryAssignment.objects.select_related("order", "agent").get(pk=id)
            )
        except (DeliveryAssignment.DoesNotExist, ValueError, ValidationError):
            return Response(
                {"detail": "Assignment not found."}, status=status.HTTP_404_NOT_FOUND
            )

        # Visible scope check first (no existence leak), then actor check.
        visible_ids = set(
            _scoped_delivery_qs(request.user).values_list("id", flat=True)
        )
        if assignment.id not in visible_ids:
            return Response(
                {"detail": "Assignment not found."}, status=status.HTTP_404_NOT_FOUND
            )
        allowed_actor = (
            request.user.is_staff
            or assignment.agent_id == request.user.id
            or is_tenant_member(request.user, assignment.tenant)
        )
        if not allowed_actor:
            return Response(
                {"detail": "Only the assigned agent or the merchant can update this."},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = DeliveryStatusUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        target = serializer.validated_data["status"]
        if not assignment.can_transition_to(target):
            return Response(
                {"detail": f"Cannot move from {assignment.status} to {target}."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        with transaction.atomic():
            assignment = DeliveryAssignment.objects.select_for_update().get(
                pk=assignment.pk
            )
            if not assignment.can_transition_to(target):
                return Response(
                    {"detail": f"Cannot move from {assignment.status} to {target}."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            assignment.status = target
            assignment.stamp_transition(target)
            if serializer.validated_data.get("note"):
                assignment.note = serializer.validated_data["note"]
            assignment.save()
            assignment.sync_order_status()

        return Response(DeliveryAssignmentSerializer(assignment).data)


class DeliveryAgentListView(viewsets.GenericViewSet):
    """GET /api/v1/admin/agents/ — verified delivery agents (staff + tenant
    members need this to assign deliveries). Minimal fields only."""

    permission_classes = [IsAuthenticated, IsTenantWriter]

    def list(self, request):
        from django.contrib.auth import get_user_model

        User = get_user_model()
        agents = User.objects.filter(
            role=User.Role.DELIVERY_AGENT,
            is_email_verified=True,
            is_active=True,
        )
        user = request.user
        if not user.is_staff:
            # Tenant members see agents already assigned within their tenants,
            # plus the unassigned pool. Never other tenants' agent emails.
            tenant_ids = user_tenant_ids(user)
            agents = agents.filter(
                Q(delivery_assignments__tenant_id__in=tenant_ids)
                | Q(delivery_assignments__isnull=True)
            ).distinct()
        agents = agents.order_by("email").values(
            "id", "email", "first_name", "last_name"
        )[:200]
        return Response(list(agents))
