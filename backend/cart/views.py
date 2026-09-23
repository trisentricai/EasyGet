from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly

from .models import Cart, CartItem
from .serializers import CartSerializer, CartItemSerializer, CartWriteSerializer


class CartViewSet(viewsets.ModelViewSet):
    """Cart API.
    GET/POST /api/v1/cart/ — current user's cart (creates if needed)
    GET/PUT/DELETE /api/v1/cart/items/{id}/ — cart items
    """

    lookup_field = "id"
    serializer_class = CartSerializer

    def get_permissions(self):
        if self.request.method in {"GET", "POST", "PATCH", "DELETE"}:
            return [IsAuthenticated()]
        return [IsAdminOnly()]

    def get_queryset(self):
        user = self.request.user
        qs = Cart.objects.select_related("store", "tenant").prefetch_related(
            "items__variant", "items__variant__product"
        )
        if user.is_staff:
            return qs
        return qs.filter(user=user)

    def get_serializer_class(self):
        if self.action in {"create", "update", "partial_update"}:
            return CartWriteSerializer
        return CartSerializer

    def get_object(self):
        """Always return/create the current user's cart."""
        if self.request.user.is_staff:
            return super().get_object()
        cart, _ = Cart.objects.get_or_create(user=self.request.user)
        return cart

    def list(self, request, *args, **kwargs):
        """Return single cart for current user."""
        cart = self.get_object()
        serializer = self.get_serializer(cart)
        return Response(serializer.data)

    @action(detail=False, methods=["post"], url_path="items")
    def add_item(self, request):
        cart = self.get_object()
        serializer = CartItemSerializer(data=request.data, context={"cart": cart})
        serializer.is_valid(raise_exception=True)
        variant = serializer.validated_data["variant"]
        quantity = serializer.validated_data.get("quantity", 1)
        # Cross-tenant guard (same rule as inventory): a cart bound to a
        # store may only hold variants from that store's tenant. Variants
        # inherit their tenant via product. Foreign combinations return
        # 400, never silently mix catalogs.
        cart_tenant_id = cart.tenant_id or (
            cart.store.tenant_id if cart.store else None
        )
        variant_tenant_id = variant.product.tenant_id if variant.product else None
        if (
            cart_tenant_id
            and variant_tenant_id
            and variant_tenant_id != cart_tenant_id
        ):
            return Response(
                {"detail": "Variant does not belong to this store's catalog."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        item, created = CartItem.objects.get_or_create(
            cart=cart, variant=variant, defaults={"quantity": quantity}
        )
        if not created:
            item.quantity += quantity
            item.save()
        return Response(CartItemSerializer(item).data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=["patch"], url_path="items/(?P<item_id>[^/.]+)")
    def update_item(self, request, item_id=None):
        cart = self.get_object()
        item = cart.items.filter(id=item_id).first()
        if not item:
            return Response(
                {"detail": "Item not found"}, status=status.HTTP_404_NOT_FOUND
            )
        serializer = CartItemSerializer(item, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=False, methods=["delete"], url_path="items/(?P<item_id>[^/.]+)")
    def remove_item(self, request, item_id=None):
        cart = self.get_object()
        deleted, _ = cart.items.filter(id=item_id).delete()
        if not deleted:
            return Response(
                {"detail": "Item not found"}, status=status.HTTP_404_NOT_FOUND
            )
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=["post"], url_path="merge")
    def merge(self, request):
        """Merge anonymous session cart into user cart (called on login)."""
        session_key = request.data.get("session_key")
        if not session_key:
            return Response(
                {"detail": "session_key required"}, status=status.HTTP_400_BAD_REQUEST
            )
        anon_cart = Cart.objects.filter(session_key=session_key, user=None).first()
        if not anon_cart:
            return Response(
                {"detail": "Anonymous cart not found"}, status=status.HTTP_404_NOT_FOUND
            )
        user_cart, _ = Cart.objects.get_or_create(user=request.user)
        # Refuse to merge carts from different tenants (same 400 rule as items).
        anon_tenant = anon_cart.tenant_id or (
            anon_cart.store.tenant_id if anon_cart.store else None
        )
        user_tenant = user_cart.tenant_id or (
            user_cart.store.tenant_id if user_cart.store else None
        )
        if anon_tenant and user_tenant and anon_tenant != user_tenant:
            return Response(
                {"detail": "Carts belong to different stores and cannot be merged."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        user_cart.merge_with(anon_cart)
        return Response(CartSerializer(user_cart).data)

    @action(detail=False, methods=["delete"], url_path="clear")
    def clear(self, request):
        cart = self.get_object()
        cart.items.all().delete()
        return Response(status=status.HTTP_204_NO_CONTENT)