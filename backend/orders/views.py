from django.db import transaction
from django.db.models import Q
from rest_framework import serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly, IsAdminOrStoreManager

from cart.models import Cart
from products.models import ProductVariant
from tenants.services import user_tenant_ids
from .models import Order, OrderItem, OrderStatusHistory
from .serializers import (
    OrderCancelSerializer,
    OrderCreateSerializer,
    OrderDetailSerializer,
    OrderListSerializer,
    OrderStatusUpdateSerializer,
)


class OrderViewSet(viewsets.ModelViewSet):
    """Order API.
    GET/POST /api/v1/orders/ — list/create orders
    GET/PATCH /api/v1/orders/{id}/ — retrieve/update order
    POST /api/v1/orders/{id}/cancel/ — cancel order
    """

    lookup_field = "id"
    serializer_class = OrderListSerializer

    def get_permissions(self):
        if self.action in {"list", "retrieve", "create", "cancel"}:
            return [IsAuthenticated()]
        if self.action in {"partial_update", "update"}:
            return [IsAdminOrStoreManager()]
        return [IsAdminOnly()]

    def get_queryset(self):
        user = self.request.user
        qs = Order.objects.select_related("store", "tenant", "user").prefetch_related(
            "items__variant", "status_history"
        )
        if user.is_staff:
            return qs
        # Tenant members see their merchants' orders; everyone else sees
        # only their own. (Previously any STORE_MANAGER saw ALL orders —
        # a cross-tenant leak.)
        tenant_ids = user_tenant_ids(user)
        if tenant_ids:
            return qs.filter(
                Q(tenant_id__in=tenant_ids) | Q(user=user)
            ).distinct()
        return qs.filter(user=user)

    def get_serializer_class(self):
        if self.action == "retrieve":
            return OrderDetailSerializer
        if self.action == "create":
            return OrderCreateSerializer
        if self.action in {"partial_update", "update"}:
            return OrderStatusUpdateSerializer
        if self.action == "cancel":
            return OrderCancelSerializer
        return OrderListSerializer

    def perform_create(self, serializer):
        cart = serializer.validated_data.pop("cart_id")
        store = serializer.validated_data.get("store")
        # The platform storefront row never fulfils orders.
        if store and store.is_platform:
            raise serializers.ValidationError(
                {"store": "Cannot place orders against the platform store."}
            )
        # The cart must belong to the caller and match the order's store.
        if cart.store_id and store and cart.store_id != store.id:
            raise serializers.ValidationError(
                {"store": "Order store does not match the cart's store."}
            )
        # Every cart line must come from the order store's tenant catalog.
        store_tenant_id = store.tenant_id if store else None
        for item in cart.items.select_related("variant__product"):
            item_tenant = (
                item.variant.product.tenant_id if item.variant.product else None
            )
            if store_tenant_id and item_tenant and item_tenant != store_tenant_id:
                raise serializers.ValidationError(
                    {"cart_id": "Cart holds items from another store's catalog."}
                )
        with transaction.atomic():
            order = serializer.save(
                user=self.request.user,
                tenant=store.tenant if store and store.tenant_id else None,
                subtotal=cart.subtotal,
                total=cart.subtotal,  # delivery_fee/discount added later
            )
            # Create order items from cart
            for item in cart.items.select_related("variant__product"):
                OrderItem.objects.create(
                    order=order,
                    variant=item.variant,
                    product_name=item.variant.product.name,
                    variant_name=item.variant.name,
                    sku=item.variant.sku,
                    unit_price=item.variant.price,
                    quantity=item.quantity,
                    line_total=item.line_total,
                )
            # Update totals
            order.subtotal = cart.subtotal
            order.total = cart.subtotal  # + delivery - discount later
            order.save()
            # Clear cart
            cart.items.all().delete()

    @action(detail=True, methods=["post"])
    def cancel(self, request, id=None):
        order = self.get_object()
        if not order.can_cancel():
            return Response(
                {"detail": f"Cannot cancel order in {order.status} status"},
                status=status.HTTP_400_BAD_REQUEST,
            )
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        with transaction.atomic():
            order.status = Order.Status.CANCELLED
            order.cancellation_reason = serializer.validated_data["reason"]
            order.cancelled_at = transaction.now()
            order.save()
            OrderStatusHistory.objects.create(
                order=order,
                from_status=order.status,
                to_status=Order.Status.CANCELLED,
                changed_by=request.user,
                note=serializer.validated_data["reason"],
            )
        return Response(OrderDetailSerializer(order).data)

    @action(detail=True, methods=["get"])
    def invoice(self, request, id=None):
        order = self.get_object()
        # Return detailed order for invoice generation
        return Response(OrderDetailSerializer(order).data)