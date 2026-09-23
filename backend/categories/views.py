from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly, role_required

from .models import Category
from .serializers import (
    CategoryDetailSerializer,
    CategoryListSerializer,
    CategoryWriteSerializer,
)


class CategoryListView(generics.ListCreateAPIView):
    """GET /api/v1/categories/ — active categories (admin sees all, incl. inactive).
    POST /api/v1/categories/ — admin only."""

    queryset = Category.objects.all()
    serializer_class = CategoryListSerializer

    def get_permissions(self):
        if self.request.method == "GET":
            return [IsAuthenticated()]
        return [IsAdminOnly()]

    def get_queryset(self):
        qs = Category.objects.all()
        if not self.request.user.is_staff:
            qs = qs.filter(is_active=True)
        return qs


class CategoryDetailView(generics.RetrieveUpdateDestroyAPIView):
    """GET /api/v1/categories/{slug}/ — public-active only for non-staff.
    PATCH/DELETE — admin only. DELETE blocked while children/products exist."""

    lookup_field = "slug"
    serializer_class = CategoryDetailSerializer

    def get_permissions(self):
        if self.request.method == "GET":
            return [IsAuthenticated()]
        return [IsAdminOnly()]

    def get_queryset(self):
        qs = Category.objects.all()
        if not self.request.user.is_staff:
            qs = qs.filter(is_active=True)
        return qs

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance.children.exists() or instance.products.exists():
            return Response(
                {"detail": "Category has subcategories or products."},
                status=status.HTTP_409_CONFLICT,
            )
        return super().destroy(request, *args, **kwargs)
