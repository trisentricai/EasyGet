"""Server-side pagination defaults for every list endpoint.

Perf spec: no list view may return an unbounded payload — 20 items per
page, and clients may not request more (`max_page_size`).
"""

from rest_framework.pagination import PageNumberPagination


class Max20PagePagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 20
