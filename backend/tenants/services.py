"""Tenant resolution and provisioning helpers.

Design note (deviation from PROJECT.md §3.3 step 2): a Django *middleware*
cannot resolve the tenant for DRF requests, because JWT authentication happens
at view time, not middleware time — request.user is still AnonymousUser there.
The same guarantee ("server-side membership verification — never trust client
headers") is implemented instead via these helpers plus the permission
classes in tenants.permissions, which run inside the DRF auth flow.
"""

from django.db import transaction
from rest_framework.exceptions import ValidationError

from .models import Tenant, TenantMembership


def active_memberships(user):
    """QuerySet of the user's active memberships (empty for anonymous)."""
    if not getattr(user, "is_authenticated", False):
        return TenantMembership.objects.none()
    return TenantMembership.objects.filter(
        user=user, is_active=True
    ).select_related("tenant")


def user_tenant_ids(user):
    """IDs of all tenants the user actively belongs to."""
    return list(active_memberships(user).values_list("tenant_id", flat=True))


def membership_role(user, tenant):
    """The user's role in `tenant`, or None if not a member."""
    if tenant is None:
        return None
    membership = active_memberships(user).filter(tenant_id=tenant.pk).first()
    return membership.role if membership else None


def is_tenant_member(user, tenant) -> bool:
    """Platform staff, or an active member (any role) of this tenant."""
    if not getattr(user, "is_authenticated", False):
        return False
    if user.is_staff:
        return True
    return membership_role(user, tenant) is not None


def is_tenant_admin(user, tenant) -> bool:
    """Platform staff, or an OWNER member of this tenant."""
    if not getattr(user, "is_authenticated", False):
        return False
    if user.is_staff:
        return True
    return membership_role(user, tenant) == TenantMembership.Role.OWNER


@transaction.atomic
def provision_tenant(user, name):
    """Create a new tenant with `user` as its OWNER member."""
    tenant = Tenant.objects.create(name=name)
    TenantMembership.objects.create(
        tenant=tenant, user=user, role=TenantMembership.Role.OWNER
    )
    return tenant


def resolve_tenant_for_create(user):
    """Pick the tenant a newly created object should belong to.

    - exactly one active membership (or one OWNER among several): that tenant
    - several ambiguous memberships: 400 telling the caller to disambiguate
    - no memberships: None (platform object — callers decide whether that is
      allowed: staff may create platform objects, customers may not)
    """
    memberships = list(active_memberships(user))
    if not memberships:
        return None
    if len(memberships) == 1:
        return memberships[0].tenant
    owners = [m for m in memberships if m.role == TenantMembership.Role.OWNER]
    if len(owners) == 1:
        return owners[0].tenant
    raise ValidationError(
        {"tenant": "User belongs to multiple tenants; specify one explicitly."}
    )
