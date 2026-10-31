from rest_framework import generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.generics import RetrieveUpdateAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Address, User
from .permissions import IsAdminOnly, IsVerifiedEmail
from .serializers import (
    AddressSerializer,
    AdminUserCreateSerializer,
    AdminUserUpdateSerializer,
    UserSerializer,
)


class MeView(RetrieveUpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated, IsVerifiedEmail]

    def get_object(self):
        return self.request.user


class AddressViewSet(viewsets.ModelViewSet):
    serializer_class = AddressSerializer
    permission_classes = [IsAuthenticated, IsVerifiedEmail]

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user).order_by("-is_default", "-updated_at")

    def perform_create(self, serializer):
        if not Address.objects.filter(user=self.request.user).exists():
            serializer.save(user=self.request.user, is_default=True)
        else:
            serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"], url_path="set-default")
    def set_default(self, request, pk=None):
        address = self.get_object()
        Address.objects.filter(user=request.user, is_default=True).update(is_default=False)
        address.is_default = True
        address.save(update_fields=["is_default", "updated_at"])
        return Response(AddressSerializer(address).data)


class AdminOnlyView(APIView):
    """Probe endpoint: CUSTOMER tokens must receive 403 here."""
    permission_classes = [IsAuthenticated, IsAdminOnly]

    def get(self, request):
        return Response({"message": "Admin access granted."}, status=status.HTTP_200_OK)


class AdminUserListCreateView(generics.ListCreateAPIView):
    """GET /api/v1/admin/users/ — every account (where users live).
    POST — create with any role (admin vouches: verified, no OTP email).
    Staff only. No DELETE: user rows anchor orders/carts; deactivate instead.
    """

    permission_classes = [IsAuthenticated, IsAdminOnly]
    queryset = User.objects.all().order_by("-id")

    def get_serializer_class(self):
        if self.request.method == "POST":
            return AdminUserCreateSerializer
        return UserSerializer


class AdminUserUpdateView(generics.RetrieveUpdateAPIView):
    """PATCH /api/v1/admin/users/<id>/ — role and active status only."""

    permission_classes = [IsAuthenticated, IsAdminOnly]
    queryset = User.objects.all()

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return AdminUserUpdateSerializer
        return UserSerializer