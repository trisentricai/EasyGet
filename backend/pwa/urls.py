from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("config", views.PWAConfigViewSet, basename="pwa-config")
router.register("push", views.PushSubscriptionViewSet, basename="push-subscription")
router.register("offline", views.OfflineDataViewSet, basename="offline-data")
router.register("updates", views.AppUpdateViewSet, basename="app-update")

urlpatterns = [
    path("", include(router.urls)),
    path("sw/", views.ServiceWorkerView.as_view({"get": "service_worker"}), name="service-worker"),
    path("manifest.json", views.ServiceWorkerView.as_view({"get": "manifest"}), name="pwa-manifest"),
    path("offline.html", views.ServiceWorkerView.as_view({"get": "offline"}), name="offline"),
]