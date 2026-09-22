from rest_framework.permissions import BasePermission

from .services import active_memberships, is_tenant_admin, is_tenant_member


class IsTenantWriter(BasePermission):
    """May create tenant-owned objects: platform staff or any active member."""

    message = "You must belong to a merchant tenant to create this resource."

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_staff:
            return True
        return active_memberships(user).exists()


class IsTenantObjectAdmin(BasePermission):
    """Object write access: platform staff or OWNER member of the object's tenant.

    Objects with no tenant (legacy/platform) are staff-only.
    """

    message = "Only the tenant owner or a platform admin can modify this object."

    def has_object_permission(self, request, view, obj):
        tenant = getattr(obj, "tenant", None)
        if tenant is None:
            user = request.user
            return bool(
                user and user.is_authenticated and user.is_staff
            )
        return is_tenant_admin(request.user, tenant)


class IsTenantObjectMember(BasePermission):
    """Object write access: platform staff or any active member of the object's tenant.

    Objects with no tenant (legacy/platform) are staff-only.
    """

    message = "You do not belong to this merchant's tenant."

    def has_object_permission(self, request, view, obj):
        tenant = getattr(obj, "tenant", None)
        if tenant is None:
            user = request.user
            return bool(
                user and user.is_authenticated and user.is_staff
            )
        return is_tenant_member(request.user, tenant)
