from django.urls import path

from .views import health, pincode

urlpatterns = [
    path("health/", health, name="health"),
    path("pincode/<str:pin>/", pincode, name="pincode-check"),
]
