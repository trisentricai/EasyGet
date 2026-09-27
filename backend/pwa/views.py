from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.utils.decorators import method_decorator
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response

from users.permissions import IsAdminOnly

from .models import AppUpdate, OfflineData, PWAConfigModel, PushSubscription
from .serializers import (
    AppUpdateCheckSerializer,
    AppUpdateSerializer,
    OfflineDataCreateSerializer,
    OfflineDataSerializer,
    PushSubscriptionCreateSerializer,
    PushSubscriptionSerializer,
    PWAConfigSerializer,
)


class PWAConfigViewSet(viewsets.ReadOnlyModelViewSet):
    """PWA configuration."""

    queryset = PWAConfigModel.objects.all()
    serializer_class = PWAConfigSerializer
    permission_classes = [AllowAny]

    def get_object(self):
        config, _ = PWAConfigModel.objects.get_or_create(id=1)
        return config


class PushSubscriptionViewSet(viewsets.ModelViewSet):
    """Push notification subscriptions."""

    serializer_class = PushSubscriptionSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return PushSubscriptionCreateSerializer
        return PushSubscriptionSerializer

    def get_queryset(self):
        return PushSubscription.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class OfflineDataViewSet(viewsets.ModelViewSet):
    """Offline data sync."""

    serializer_class = OfflineDataSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action in ["create", "update", "partial_update"]:
            return OfflineDataCreateSerializer
        return OfflineDataSerializer

    def get_queryset(self):
        return OfflineData.objects.filter(user=self.request.user)

    @action(detail=False, methods=["post"])
    def sync(self, request):
        """Bulk sync offline data."""
        items = request.data.get("items", [])
        results = {"created": 0, "updated": 0, "errors": []}

        for item in items:
            serializer = OfflineDataCreateSerializer(
                data=item, context={"request": request}
            )
            if serializer.is_valid():
                obj, created = OfflineData.objects.update_or_create(
                    user=request.user,
                    data_type=item["data_type"],
                    key=item["key"],
                    defaults={
                        "data": item["data"],
                        "expires_at": item.get("expires_at"),
                    },
                )
                if created:
                    results["created"] += 1
                else:
                    results["updated"] += 1
            else:
                results["errors"].append({"item": item, "errors": serializer.errors})

        return Response(results)


class AppUpdateViewSet(viewsets.ModelViewSet):
    """App update management. Reads/checks are public; every write is staff-only
    (anonymous clients must never create, edit, or delete update records —
    download_url is served back to all devices by the check action)."""

    queryset = AppUpdate.objects.all()
    serializer_class = AppUpdateSerializer
    permission_classes = [IsAdminOnly]

    def get_permissions(self):
        if self.action in {"list", "retrieve", "check"}:
            return [AllowAny()]
        return [IsAdminOnly()]

    def get_serializer_class(self):
        if self.action == "check":
            return AppUpdateCheckSerializer
        return AppUpdateSerializer

    def get_queryset(self):
        if self.request.user.is_staff:
            return AppUpdate.objects.all()
        return AppUpdate.objects.filter(status=AppUpdate.Status.DEPLOYED)

    @action(detail=False, methods=["post"], permission_classes=[AllowAny])
    def check(self, request):
        """Check for app updates."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        platform = serializer.validated_data["platform"]
        current_version = serializer.validated_data["current_version"]

        from packaging import version

        latest = AppUpdate.objects.filter(
            platform=platform,
            status=AppUpdate.Status.DEPLOYED,
        ).first()

        if not latest:
            return Response({"update_available": False})

        has_update = version.parse(latest.version) > version.parse(current_version)

        if has_update:
            mandatory = latest.is_mandatory or (
                latest.min_supported_version and
                version.parse(current_version) < version.parse(latest.min_supported_version)
            )
            return Response({
                "update_available": True,
                "version": latest.version,
                "release_notes": latest.release_notes,
                "download_url": latest.download_url,
                "is_mandatory": mandatory,
            })

        return Response({"update_available": False})

    @action(detail=True, methods=["post"], permission_classes=[IsAdminOnly])
    def mark_deployed(self, request, pk=None):
        update = self.get_object()
        if request.user.is_staff:
            update.status = AppUpdate.Status.DEPLOYED
            update.released_at = timezone.now()
            update.save()
            return Response({"status": "deployed"})
        return Response({"error": "Unauthorized"}, status=403)


class ServiceWorkerView(viewsets.GenericViewSet):
    """Serve service worker and manifest."""

    permission_classes = [AllowAny]

    @action(detail=False, methods=["get"], url_path="manifest.json")
    def manifest(self, request):
        config = PWAConfigModel.objects.first()
        if not config:
            config = PWAConfigModel.objects.create()
        return JsonResponse(config.get_manifest())

    @action(detail=False, methods=["get"], url_path="service-worker.js")
    def service_worker(self, request):
        sw_content = """
// EasyGet Service Worker
const CACHE_NAME = 'easyget-v1';
const STATIC_ASSETS = [
    '/',
    '/static/css/main.css',
    '/static/js/main.js',
    '/manifest.json',
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS))
    );
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((cacheNames) => {
            return Promise.all(
                cacheNames
                    .filter((name) => name !== CACHE_NAME)
                    .map((name) => caches.delete(name))
            );
        })
    );
    self.clients.claim();
});

self.addEventListener('fetch', (event) => {
    if (event.request.method !== 'GET') return;

    event.respondWith(
        caches.match(event.request).then((cachedResponse) => {
            if (cachedResponse) return cachedResponse;

            return fetch(event.request).then((response) => {
                if (!response || response.status !== 200 || response.type !== 'basic') {
                    return response;
                }
                const responseToCache = response.clone();
                caches.open(CACHE_NAME).then((cache) => {
                    cache.put(event.request, responseToCache);
                });
                return response;
            });
        })
    );
});

self.addEventListener('push', (event) => {
    if (!event.data) return;

    const data = event.data.json();
    const options = {
        body: data.body,
        icon: '/static/pwa/icon-192.png',
        badge: '/static/pwa/badge-72.png',
        vibrate: [100, 50, 100],
        data: data.data,
        actions: data.actions || [],
    };

    event.waitUntil(
        self.registration.showNotification(data.title, options)
    );
});

self.addEventListener('notificationclick', (event) => {
    event.notification.close();
    const url = event.notification.data?.url || '/';

    event.waitUntil(
        clients.matchAll({ type: 'window' }).then((clientList) => {
            for (const client of clientList) {
                if (client.url === url && 'focus' in client) return client.focus();
            }
            if (clients.openWindow) return clients.openWindow(url);
        })
    );
});
"""
        return JsonResponse(sw_content, safe=False, content_type="application/javascript")

    @action(detail=False, methods=["get"], url_path="offline.html")
    def offline(self, request):
        offline_html = """
<!DOCTYPE html>
<html>
<head>
    <title>Offline - EasyGet</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: system-ui; text-align: center; padding: 50px; background: #f3f4f6; }
        .container { max-width: 400px; margin: 0 auto; background: white; padding: 40px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #1f2937; margin-bottom: 16px; }
        p { color: #6b7280; margin-bottom: 24px; }
        button { background: #2563eb; color: white; border: none; padding: 12px 24px; border-radius: 8px; font-size: 16px; cursor: pointer; }
        button:hover { background: #1d4ed8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>You're Offline</h1>
        <p>It looks like you've lost your internet connection. Please check your connection and try again.</p>
        <button onclick="window.location.reload()">Retry</button>
    </div>
</body>
</html>
"""
        return JsonResponse(offline_html, safe=False, content_type="text/html")