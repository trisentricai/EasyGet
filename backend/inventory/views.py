from django.db import transaction
from django.db.models import F
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from tenants.permissions import IsTenantWriter
from tenants.services import is_tenant_member, user_tenant_ids

from .models import InventoryTransaction, StockItem
from .serializers import (
    InventoryTransactionSerializer,
    StockItemAdjustSerializer,
    StockItemListSerializer,
    StockItemWriteSerializer,
)


def _scoped_stock_qs(user):
    """Stock visibility: staff see all; tenant members see their tenants' stock;
    everyone else sees stock of active stores (public real-time availability)."""
    qs = StockItem.objects.select_related(
        "store", "variant", "variant__product", "tenant"
    )
    if user.is_staff:
        return qs
    tenant_ids = user_tenant_ids(user)
    if tenant_ids:
        return qs.filter(tenant_id__in=tenant_ids)
    return qs.filter(store__is_active=True)


class StockItemListView(generics.ListCreateAPIView):
    """GET /api/v1/inventory/ — tenant-scoped stock (public sees active stores only).
    POST /api/v1/inventory/ — staff or tenant members; the stock item is bound
    to the store's tenant and the variant must belong to the same tenant.
    """

    def get_permissions(self):
        if self.request.method == "GET":
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsTenantWriter()]

    def get_queryset(self):
        return _scoped_stock_qs(self.request.user)

    def get_serializer_class(self):
        if self.request.method in {"POST", "PUT"}:
            return StockItemWriteSerializer
        return StockItemListSerializer


class LowStockListView(generics.ListAPIView):
    """GET /api/v1/inventory/low-stock/ — same scoping as the stock list."""

    permission_classes = [IsAuthenticated]
    serializer_class = StockItemListSerializer

    def get_queryset(self):
        return _scoped_stock_qs(self.request.user).filter(
            quantity__lte=F("low_stock_threshold")
        )


class TransactionListView(generics.ListAPIView):
    """GET /api/v1/inventory/transactions/ — staff see all; tenant members see
    their tenants' movements; others see only what they performed themselves."""

    permission_classes = [IsAuthenticated]
    serializer_class = InventoryTransactionSerializer

    def get_queryset(self):
        user = self.request.user
        qs = InventoryTransaction.objects.select_related(
            "stock_item", "stock_item__store", "stock_item__variant", "performed_by"
        )
        if user.is_staff:
            return qs
        tenant_ids = user_tenant_ids(user)
        if tenant_ids:
            return qs.filter(stock_item__tenant_id__in=tenant_ids)
        return qs.filter(performed_by=user)


class StockAdjustView(generics.GenericAPIView):
    """POST /api/v1/inventory/{pk}/adjust/ — staff or a member of the stock
    item's tenant. Body: {"change": N, "reason": "RESTOCK|SALE|...", "note": "..."}.

    Runs under a row lock (select_for_update) so concurrent adjustments cannot
    race, and writes an InventoryTransaction audit row. Quantity never drops
    below zero. Foreign-tenant items return 404 (no existence leak).
    """

    permission_classes = [IsAuthenticated]
    serializer_class = StockItemAdjustSerializer

    def post(self, request, pk):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        with transaction.atomic():
            try:
                stock_item = (
                    StockItem.objects.select_for_update()
                    .select_related("store", "variant")
                    .get(pk=pk)
                )
            except StockItem.DoesNotExist:
                return Response({"detail": "Stock item not found."}, status=404)

            if not is_tenant_member(request.user, stock_item.tenant):
                return Response({"detail": "Stock item not found."}, status=404)

            new_quantity = stock_item.quantity + data["change"]
            if new_quantity < 0:
                return Response(
                    {"detail": "Quantity cannot go below zero.", "requested": new_quantity},
                    status=400,
                )

            stock_item.quantity = new_quantity
            stock_item.save(update_fields=["quantity", "updated_at"])
            InventoryTransaction.objects.create(
                stock_item=stock_item,
                change=data["change"],
                reason=data["reason"],
                note=data.get("note", ""),
                performed_by=request.user,
            )

        return Response(StockItemListSerializer(stock_item).data, status=200)
