from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("me/addresses", views.AddressViewSet, basename="address")

urlpatterns = [
    path("me/", views.MeView.as_view(), name="me"),
    path(
        "me/change-password/",
        views.ChangePasswordView.as_view(),
        name="change-password",
    ),
    path("", include(router.urls)),
]