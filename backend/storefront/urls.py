from django.urls import path

from . import views

urlpatterns = [
    # Before <slug:store_slug>/ — "platform" is a valid slug otherwise.
    path("platform/", views.PlatformStorefrontView.as_view()),
    path("<slug:store_slug>/", views.StorefrontRenderView.as_view()),
    path("<slug:store_slug>/theme/", views.StorefrontThemeView.as_view()),
    path("<slug:store_slug>/sections/", views.SectionListCreateView.as_view()),
    path(
        "<slug:store_slug>/sections/reorder/",
        views.SectionReorderView.as_view(),
    ),
    path("sections/<int:pk>/", views.SectionDetailView.as_view()),
    path("sections/<int:pk>/items/", views.SectionItemsView.as_view()),
    path(
        "sections/<int:pk>/items/reorder/",
        views.ItemReorderView.as_view(),
    ),
    path("items/<int:pk>/", views.ItemDetailView.as_view()),
]
