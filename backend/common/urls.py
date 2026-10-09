from django.urls import path

from .views import banners, health, pincode

urlpatterns = [
    path("health/", health, name="health"),
    path("pincode/<str:pin>/", pincode, name="pincode-check"),
    path("banners/", banners, name="banners-list"),
]
