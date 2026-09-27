from django.db import transaction
from rest_framework import generics
from rest_framework.permissions import IsAuthenticated

from tenants.permissions import IsTenantObjectAdmin
from tenants.services import provision_tenant, resolve_tenant_for_create
from users.permissions import IsVerifiedEmail

from .models import Store
from .serializers import (
    StoreDetailSerializer,
    StoreListSerializer,
    StoreWriteSerializer,
)


class StoreListView(generics.ListCreateAPIView):
    """GET /api/v1/stores/ — active stores (+optional ?lat=&lng= distance), staff sees all.
    POST /api/v1/stores/ — verified users only; merchant onboarding.

    On create, the store is linked to a tenant: the creator's existing single
    tenant membership if they have one, otherwise a fresh tenant is provisioned
    with the creator as its OWNER (the SaaS "merchant signs up" flow).
    """

    queryset = Store.objects.all()

    def get_permissions(self):
        if self.request.method == "GET":
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsVerifiedEmail()]

    def get_queryset(self):
        qs = Store.objects.select_related("tenant")
        if not self.request.user.is_staff:
            qs = qs.filter(is_active=True, is_platform=False)
        return qs

    def get_serializer_class(self):
        if self.request.method in {"POST", "PUT", "PATCH"}:
            return StoreWriteSerializer
        return StoreListSerializer

    def perform_create(self, serializer):
        user = self.request.user
        with transaction.atomic():
            store = serializer.save()
            if store.tenant_id is None:
                tenant = resolve_tenant_for_create(user)
                if tenant is None:
                    tenant = provision_tenant(user, store.name)
                store.tenant = tenant
                store.save(update_fields=["tenant"])


class StoreDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET /api/v1/stores/{slug}/ — active stores for everyone (staff sees all).
    PATCH/DELETE /api/v1/stores/{slug}/ — the store's tenant OWNER or platform admin.
    """

    lookup_field = "slug"

    def get_permissions(self):
        if self.request.method == "GET":
            return [IsAuthenticated()]
        return [IsAuthenticated(), IsTenantObjectAdmin()]

    def get_queryset(self):
        qs = Store.objects.select_related("tenant")
        if self.request.method == "GET" and not self.request.user.is_staff:
            qs = qs.filter(is_active=True, is_platform=False)
        return qs

    def get_serializer_class(self):
        if self.request.method in {"PATCH", "PUT", "POST"}:
            return StoreWriteSerializer
        return StoreDetailSerializer
