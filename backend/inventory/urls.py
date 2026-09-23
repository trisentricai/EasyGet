from django.urls import path

from . import views

urlpatterns = [
    path("", views.StockItemListView.as_view(), name="stockitem-list"),
    path(
        "low-stock/",
        views.LowStockListView.as_view(),
        name="stockitem-low-stock",
    ),
    path(
        "transactions/",
        views.TransactionListView.as_view(),
        name="transaction-list",
    ),
    path(
        "<int:pk>/adjust/",
        views.StockAdjustView.as_view(),
        name="stockitem-adjust",
    ),
]
