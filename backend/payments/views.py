from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly, IsAdminOrStoreManager

from .models import Payment, PaymentMethod, Refund
from .serializers import (
    PaymentCreateSerializer,
    PaymentMethodCreateSerializer,
    PaymentMethodSerializer,
    PaymentSerializer,
    RefundCreateSerializer,
    RefundSerializer,
)


class PaymentMethodViewSet(viewsets.ModelViewSet):
    """User's saved payment methods."""

    serializer_class = PaymentMethodSerializer

    def get_permissions(self):
        return [IsAuthenticated()]

    def get_queryset(self):
        return PaymentMethod.objects.filter(user=self.request.user, is_active=True)

    def get_serializer_class(self):
        if self.action in {"create", "update", "partial_update"}:
            return PaymentMethodCreateSerializer
        return PaymentMethodSerializer

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class PaymentViewSet(viewsets.ModelViewSet):
    """Payment processing."""

    serializer_class = PaymentSerializer

    def get_permissions(self):
        if self.action in {"create", "list", "retrieve"}:
            return [IsAuthenticated()]
        if self.action in {"webhook", "refund"}:
            return [IsAdminOrStoreManager()]
        return [IsAdminOnly()]

    def get_queryset(self):
        user = self.request.user
        if user.is_staff or user.role == user.Role.STORE_MANAGER:
            return Payment.objects.all()
        return Payment.objects.filter(user=user)

    def get_serializer_class(self):
        if self.action == "create":
            return PaymentCreateSerializer
        if self.action == "refund":
            return RefundCreateSerializer
        return PaymentSerializer

    def perform_create(self, serializer):
        payment = serializer.save(user=self.request.user)
        # In real implementation, create gateway order here
        # payment.gateway_order_id = gateway.create_order(...)
        # payment.save()

    @action(detail=True, methods=["post"], permission_classes=[IsAdminOrStoreManager])
    def refund(self, request, id=None):
        payment = self.get_object()
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        refund = serializer.save(payment=payment)
        # Process refund with gateway
        return Response(RefundSerializer(refund).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=["post"], permission_classes=[IsAdminOrStoreManager])
    def webhook(self, request):
        """Handle payment gateway webhooks."""
        gateway = request.data.get("gateway")
        event = request.data.get("event")
        payload = request.data.get("payload", {})

        # Verify webhook signature in real implementation
        # gateway.verify_webhook(request)

        payment_id = payload.get("payment_id") or payload.get("order_id")
        if not payment_id:
            return Response(
                {"detail": "payment_id required"}, status=status.HTTP_400_BAD_REQUEST
            )

        try:
            payment = Payment.objects.get(gateway_payment_id=payment_id)
        except Payment.DoesNotExist:
            return Response(
                {"detail": "Payment not found"}, status=status.HTTP_404_NOT_FOUND
            )

        if event == "payment.captured" or event == "payment.succeeded":
            payment.mark_succeeded(gateway_response=payload)
        elif event == "payment.failed":
            payment.mark_failed(
                reason=payload.get("error_description", "Unknown error"),
                gateway_response=payload,
            )
        elif event == "refund.succeeded":
            refund_id = payload.get("refund_id")
            Refund.objects.filter(gateway_refund_id=refund_id).update(
                status=Refund.Status.SUCCEEDED, processed_at=timezone.now()
            )

        return Response({"status": "ok"})


class RefundViewSet(viewsets.ModelViewSet):
    """Refund management."""

    serializer_class = RefundSerializer

    def get_permissions(self):
        return [IsAdminOrStoreManager()]

    def get_queryset(self):
        return Refund.objects.all()