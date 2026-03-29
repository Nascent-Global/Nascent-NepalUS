from django.db.models import Avg
from rest_framework import filters, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import BurnoutCause, BurnoutScore, DailyEntry, ScoreLog
from .serializers import (
    BurnoutCauseSerializer,
    BurnoutScoreSerializer,
    DailyEntrySerializer,
    ScoreLogSerializer,
)


# Pagination
class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 200


# ViewSets
class DailyEntryViewSet(viewsets.ModelViewSet):
    """
    CRUD for DailyEntry
    Query params:
      - ?date=YYYY-MM-DD
      - ?since=YYYY-MM-DD
      - ?until=YYYY-MM-DD
    """

    queryset = DailyEntry.objects.all().order_by("-date", "-created_at")
    serializer_class = DailyEntrySerializer

    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    ordering_fields = ["date", "created_at"]
    search_fields = []

    def get_queryset(self):
        qs = super().get_queryset()
        req = self.request
        date = req.query_params.get("date")
        since = req.query_params.get("since")
        until = req.query_params.get("until")
        if date:
            qs = qs.filter(date=date)
        if since:
            qs = qs.filter(date__gte=since)
        if until:
            qs = qs.filter(date__lte=until)
        return qs


class BurnoutScoreViewSet(viewsets.ModelViewSet):
    """
    CRUD for BurnoutScore
    Extra endpoints:
      - GET /burnout_scores/latest/  -> latest score
      - GET /burnout_scores/trend/   -> average score per date
    """

    queryset = BurnoutScore.objects.all().order_by("-created_at")
    serializer_class = BurnoutScoreSerializer

    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    ordering_fields = ["date", "created_at", "score"]
    search_fields = []

    @action(detail=False, methods=["get"], url_path="latest")
    def latest(self, request):
        obj = self.get_queryset().first()
        if not obj:
            return Response({})
        serializer = self.get_serializer(obj)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="trend")
    def trend(self, request):
        """
        Return average score per date.
        Optional query params: since, until (YYYY-MM-DD)
        """
        qs = self.get_queryset()
        since = request.query_params.get("since")
        until = request.query_params.get("until")
        if since:
            qs = qs.filter(date__gte=since)
        if until:
            qs = qs.filter(date__lte=until)
        # Group by date and average score
        rows = qs.values("date").annotate(avg_score=Avg("score")).order_by("date")
        return Response(list(rows))


class BurnoutCauseViewSet(viewsets.ModelViewSet):
    """
    CRUD for BurnoutCause
    Causes belong to a BurnoutScore via FK `score`
    """

    queryset = BurnoutCause.objects.all()
    serializer_class = BurnoutCauseSerializer

    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    ordering_fields = ["score", "id"]
    search_fields = ["cause_type"]

    def get_queryset(self):
        qs = super().get_queryset()
        score_id = self.request.query_params.get("score_id")
        if score_id:
            qs = qs.filter(score__id=score_id)
        return qs


class ScoreLogViewSet(viewsets.ModelViewSet):
    """
    CRUD for ScoreLog
    Logs belong to a BurnoutScore via FK `score`
    """

    queryset = ScoreLog.objects.all().order_by("-created_at")
    serializer_class = ScoreLogSerializer

    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    ordering_fields = ["created_at", "change_amount"]
    search_fields = ["reason"]

    def get_queryset(self):
        qs = super().get_queryset()
        score_id = self.request.query_params.get("score_id")
        if score_id:
            qs = qs.filter(score__id=score_id)
        return qs
