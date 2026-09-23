from django.conf import settings
from django.db import models
from django.utils.text import slugify


class Tenant(models.Model):
    """A merchant organization on the platform.

    This is the root of multi-tenant isolation: stores, products and stock
    belong to a tenant, and every tenant-scoped query must filter through it.
    Platform-level models (User, membership of platform staff) stay tenant-free.
    """

    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=280, unique=True, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def save(self, *args, **kwargs):
        if not self.slug:
            base = slugify(self.name) or "tenant"
            slug = base
            suffix = 1
            while Tenant.objects.filter(slug=slug).exists():
                slug = f"{base}-{suffix}"
                suffix += 1
            self.slug = slug
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class TenantMembership(models.Model):
    """Who belongs to which tenant, and with what authority.

    Membership — not client-supplied headers, not user role alone — is the
    server-side source of truth for tenant access.
    """

    class Role(models.TextChoices):
        OWNER = "OWNER", "Owner"
        MANAGER = "MANAGER", "Manager"

    tenant = models.ForeignKey(
        Tenant, on_delete=models.CASCADE, related_name="memberships"
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="tenant_memberships",
    )
    role = models.CharField(
        max_length=20, choices=Role.choices, default=Role.MANAGER
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["tenant", "user"],
                name="unique_membership_per_tenant_user",
            )
        ]

    def __str__(self):
        return f"{self.user.email} — {self.role} @ {self.tenant.name}"
