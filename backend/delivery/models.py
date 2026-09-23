import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone

from orders.models import Order
from stores.models import Store
from tenants.models import Tenant


class DeliveryAssignment(models.Model):
    """Manual (v1) delivery assignment: order → agent.

    Flow: ASSIGNED → ACCEPTED → PICKED_UP → OUT_FOR_DELIVERY → DELIVERED,
    with CANCELLED as a terminal escape from any non-delivered state.
    The customer-facing order status mirrors the delivery-relevant states
    (see `sync_order_status`). Items/history style inheritance: tenancy is
    denormalized from order.store.tenant; no per-item FKs.
    """

    class Status(models.TextChoices):
        ASSIGNED = "ASSIGNED", "Assigned"
        ACCEPTED = "ACCEPTED", "Accepted by agent"
        PICKED_UP = "PICKED_UP", "Picked up from store"
        OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY", "Out for delivery"
        DELIVERED = "DELIVERED", "Delivered"
        CANCELLED = "CANCELLED", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField(
        Order,
        on_delete=models.PROTECT,
        related_name="delivery_assignment",
    )
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="delivery_assignments",
        help_text="Denormalized from order.store.tenant.",
    )
    agent = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="delivery_assignments",
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.ASSIGNED
    )
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="created_delivery_assignments",
    )
    note = models.TextField(blank=True, default="")
    assigned_at = models.DateTimeField(auto_now_add=True)
    accepted_at = models.DateTimeField(null=True, blank=True)
    picked_up_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-assigned_at"]
        indexes = [
            models.Index(fields=["agent", "status"]),
            models.Index(fields=["tenant", "status"]),
            models.Index(fields=["order", "status"]),
        ]

    def __str__(self):
        return f"Delivery {self.order.order_number} → {self.agent.email} ({self.status})"

    def save(self, *args, **kwargs):
        if self.order_id:
            store_tenant_id = (
                Store.objects.filter(orders__id=self.order_id)
                .values_list("tenant_id", flat=True)
                .first()
            )
            if store_tenant_id:
                self.tenant_id = store_tenant_id
        super().save(*args, **kwargs)

    @staticmethod
    def valid_transitions():
        return {
            DeliveryAssignment.Status.ASSIGNED: {
                DeliveryAssignment.Status.ACCEPTED,
                DeliveryAssignment.Status.CANCELLED,
            },
            DeliveryAssignment.Status.ACCEPTED: {
                DeliveryAssignment.Status.PICKED_UP,
                DeliveryAssignment.Status.CANCELLED,
            },
            DeliveryAssignment.Status.PICKED_UP: {
                DeliveryAssignment.Status.OUT_FOR_DELIVERY,
                DeliveryAssignment.Status.CANCELLED,
            },
            DeliveryAssignment.Status.OUT_FOR_DELIVERY: {
                DeliveryAssignment.Status.DELIVERED,
                DeliveryAssignment.Status.CANCELLED,
            },
            DeliveryAssignment.Status.DELIVERED: set(),
            DeliveryAssignment.Status.CANCELLED: set(),
        }

    def can_transition_to(self, target):
        return target in self.valid_transitions().get(self.status, set())

    def stamp_transition(self, target):
        now = timezone.now()
        if target == self.Status.ACCEPTED:
            self.accepted_at = now
        elif target == self.Status.PICKED_UP:
            self.picked_up_at = now
        elif target == self.Status.DELIVERED:
            self.delivered_at = now
        elif target == self.Status.CANCELLED:
            self.cancelled_at = now

    def sync_order_status(self):
        """Mirror delivery-relevant states onto the customer-facing order."""
        mapping = {
            self.Status.OUT_FOR_DELIVERY: Order.Status.OUT_FOR_DELIVERY,
            self.Status.DELIVERED: Order.Status.DELIVERED,
        }
        target = mapping.get(self.status)
        if target is None or self.order.status == target:
            return
        # Only move forward along the order lifecycle.
        order_flow = [
            Order.Status.PENDING,
            Order.Status.CONFIRMED,
            Order.Status.PREPARING,
            Order.Status.READY,
            Order.Status.OUT_FOR_DELIVERY,
            Order.Status.DELIVERED,
        ]
        try:
            if order_flow.index(target) <= order_flow.index(self.order.status):
                return
        except ValueError:
            return
        from orders.models import OrderStatusHistory

        old = self.order.status
        self.order.status = target
        if target == Order.Status.DELIVERED:
            self.order.delivered_at = timezone.now()
        self.order.save(update_fields=["status", "delivered_at", "updated_at"])
        OrderStatusHistory.objects.create(
            order=self.order,
            from_status=old,
            to_status=target,
            changed_by=self.agent,
            note=f"Delivery update: {self.get_status_display()}",
        )
