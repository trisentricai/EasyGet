import math

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models
from django.utils.text import slugify

from tenants.models import Tenant


class Store(models.Model):
    EARTH_RADIUS_KM = 6371.0

    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="stores",
        help_text="Merchant organization that owns this store.",
    )
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=280, unique=True, blank=True)
    description = models.TextField(blank=True, default="")

    address_line1 = models.CharField(max_length=255)
    address_line2 = models.CharField(max_length=255, blank=True, default="")
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    postal_code = models.CharField(max_length=20)
    country = models.CharField(max_length=100, default="India")

    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    delivery_radius_km = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=5.00,
        validators=[MinValueValidator(0.5), MaxValueValidator(100)],
    )

    contact_phone = models.CharField(max_length=15, blank=True, default="")
    opening_time = models.TimeField(null=True, blank=True)
    closing_time = models.TimeField(null=True, blank=True)

    is_active = models.BooleanField(default=True)
    # The single platform-level row that owns EASYGET's customer storefront
    # (theme/sections). Never an order target, never shown as a seller.
    is_platform = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]
        constraints = [
            models.UniqueConstraint(
                fields=["is_platform"],
                condition=models.Q(is_platform=True),
                name="unique_platform_store",
            ),
        ]

    def save(self, *args, **kwargs):
        if not self.slug:
            base = slugify(self.name) or "store"
            slug = base
            suffix = 1
            while Store.objects.filter(slug=slug).exists():
                slug = f"{base}-{suffix}"
                suffix += 1
            self.slug = slug
        super().save(*args, **kwargs)

    @staticmethod
    def haversine_km(lat1, lon1, lat2, lon2):
        lat1, lon1, lat2, lon2 = map(float, (lat1, lon1, lat2, lon2))
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2))
            * math.sin(dlon / 2) ** 2
        )
        return 2 * Store.EARTH_RADIUS_KM * math.asin(math.sqrt(a))

    def distance_km(self, latitude, longitude):
        return self.haversine_km(self.latitude, self.longitude, latitude, longitude)

    def serves(self, latitude, longitude):
        """True if the coordinate is inside this store's delivery radius."""
        if not self.is_active:
            return False
        return self.distance_km(latitude, longitude) <= float(self.delivery_radius_km)

    def __str__(self):
        return self.name
