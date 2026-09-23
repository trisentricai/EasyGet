from django.urls import include, path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("", views.DeliveryAssignmentViewSet, basename="delivery")

urlpatterns = [
    # Before the router: the "" detail route would otherwise swallow
    # "agents/" as an assignment id lookup.
    path(
        "agents/",
        views.DeliveryAgentListView.as_view({"get": "list"}),
        name="delivery-agents",
    ),
    path("", include(router.urls)),
]
