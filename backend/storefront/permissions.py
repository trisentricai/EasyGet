from rest_framework.permissions import BasePermission

from tenants.services import is_tenant_member


def can_manage_store(user, store) -> bool:
    """Platform staff, or an active member of the store's tenant.

    Single-client note: the operator is normally a platform ADMIN (staff);
    the membership check keeps the merchant owner in control too.
    """
    if not user or not user.is_authenticated:
        return False
    if user.is_staff:
        return True
    return is_tenant_member(user, store.tenant)


class IsStorefrontManager(BasePermission):
    """Write access to a store's storefront content.

    Collection endpoints expose `get_store()` so the store comes from the URL;
    detail endpoints resolve the store per object (obj.store, or
    obj.section.store for items).
    """

    message = "Store management access required."

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        get_store = getattr(view, "get_store", None)
        if get_store is None:
            return True  # decided per-object in has_object_permission
        return can_manage_store(user, get_store())

    def has_object_permission(self, request, view, obj):
        store = getattr(obj, "store", None) or getattr(
            getattr(obj, "section", None), "store", None
        )
        return store is not None and can_manage_store(request.user, store)
