from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("templates", views.NotificationTemplateViewSet, basename="notification-template")
router.register("", views.NotificationViewSet, basename="notification")
router.register("preferences", views.NotificationPreferenceViewSet, basename="notification-preference")
router.register("admin", views.NotificationAdminViewSet, basename="notification-admin")

urlpatterns = [
    path("", include(router.urls)),
]