from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/auth/", include("users.auth_urls")),
    path("api/v1/users/", include("users.urls")),
    # admin_panel's router must be matched BEFORE users.admin_urls (same prefix;
    # Django does not fall through to later includes on a miss).
    path("api/v1/admin/", include("admin_panel.urls")),
    path("api/v1/admin/", include("users.admin_urls")),
    path("api/v1/stores/", include("stores.urls")),
    path("api/v1/categories/", include("categories.urls")),
    path("api/v1/products/", include("products.urls")),
    path("api/v1/inventory/", include("inventory.urls")),
    path("api/v1/storefront/", include("storefront.urls")),
    path("api/v1/cart/", include("cart.urls")),
    path("api/v1/orders/", include("orders.urls")),
    path("api/v1/payments/", include("payments.urls")),
    path("api/v1/notifications/", include("notifications.urls")),
    path("api/v1/search/", include("search.urls")),
    path("api/v1/analytics/", include("analytics.urls")),
    path("api/v1/realtime/", include("realtime.urls")),
    path("api/v1/admin/", include("admin_panel.urls")),
    path("api/v1/webhooks/", include("webhooks.urls")),
    path("api/v1/pwa/", include("pwa.urls")),
    path("api/v1/", include("common.urls")),
    # API Documentation
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/redoc/", SpectacularRedocView.as_view(url_name="schema"), name="redoc"),
]
