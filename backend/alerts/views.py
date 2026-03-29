from rest_framework import filters, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import Alert
from .serializers import AlertSerializer


# Pagination
class StandardResultsSetPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 200


# ViewSet (CRUD + simple filters)
class AlertViewSet(viewsets.ModelViewSet):
    """
    CRUD API for Alert.

    Supported query params:
      - ?date=YYYY-MM-DD    -> filter alerts by date
      - ?type=TEXT          -> filter by alert type
      - ?ordering=field     -> ordering by date or created_at
    Extra:
      - GET /alerts/recent/?limit=N -> most recent N alerts
    """

    queryset = Alert.objects.all().order_by("-created_at")
    serializer_class = AlertSerializer
    permission_classes = [permissions.AllowAny]  # open access for MVP
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    search_fields = ["type", "message"]
    ordering_fields = ["date", "created_at"]
    ordering = ["-created_at"]

    def get_queryset(self):
        qs = super().get_queryset()
        req = self.request
        date = req.query_params.get("date")
        type_q = req.query_params.get("type")
        if date:
            qs = qs.filter(date=date)
        if type_q:
            qs = qs.filter(type=type_q)
        return qs

    @action(detail=False, methods=["get"], url_path="recent")
    def recent(self, request):
        try:
            limit = int(request.query_params.get("limit", 5))
        except (ValueError, TypeError):
            limit = 5
        qs = self.get_queryset()[:limit]
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)
