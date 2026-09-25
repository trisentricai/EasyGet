from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("", views.ProductViewSet, basename="product")

urlpatterns = [
    # Before the router: the "" detail route (lookup by slug) would
    # otherwise swallow "brands/" as a product slug lookup.
    path("brands/", views.ProductBrandListView.as_view(), name="product-brands"),
    path("", include(router.urls)),
]
