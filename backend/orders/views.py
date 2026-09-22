from django.db import transaction
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly, IsAdminOrStoreManager

from cart.models import Cart
from products.models import ProductVariant
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
        if user.is_staff or user.role == user.Role.STORE_MANAGER:
            return Order.objects.all()
        return Order.objects.filter(user=user)

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
        with transaction.atomic():
            order = serializer.save(
                user=self.request.user,
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