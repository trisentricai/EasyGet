from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/v1/auth/", include("users.auth_urls")),
    path("api/v1/users/", include("users.urls")),
    path("api/v1/admin/", include("users.admin_urls")),
    path("api/v1/", include("common.urls")),
]
