from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("popular", views.PopularSearchViewSet, basename="popular-search")
router.register("logs", views.SearchQueryLogViewSet, basename="search-log")

urlpatterns = [
    # POST /search/ searches; GET /search/ and GET /search/suggestions/ both
    # serve autocomplete (the router never registered the @action route,
    # which left the frontend's /search/suggestions/ calls 404ing).
    path("", views.SearchViewSet.as_view({"post": "create", "get": "suggestions"}), name="search"),
    path("suggestions/", views.SearchViewSet.as_view({"get": "suggestions"}), name="search-suggestions"),
    path("", include(router.urls)),
]