from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("popular", views.PopularSearchViewSet, basename="popular-search")
router.register("logs", views.SearchQueryLogViewSet, basename="search-log")

urlpatterns = [
    path("", views.SearchViewSet.as_view({"post": "create", "get": "suggestions"}), name="search"),
    path("", include(router.urls)),
]