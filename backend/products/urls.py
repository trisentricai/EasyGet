from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("", views.ProductViewSet, basename="product")

urlpatterns = [
    # Before the router: the "" detail route (lookup by slug) would
    # otherwise swallow "brands/" as a product slug lookup.
    path("brands/", views.ProductBrandListView.as_view(), name="product-brands"),
    # "wishlist/" would likewise be read as a slug by the detail route.
    path("wishlist/", views.WishlistView.as_view(), name="product-wishlist"),
    path(
        "wishlist/<slug:slug>/",
        views.WishlistToggleView.as_view(),
        name="product-wishlist-toggle",
    ),
    # "/products/<slug>/reviews/" — deeper than the detail route, but
    # keep it ahead of the router so slug lookups can never shadow it.
    path(
        "<slug:slug>/reviews/",
        views.ProductReviewListCreateView.as_view(),
        name="product-reviews",
    ),
    path("", include(router.urls)),
]
