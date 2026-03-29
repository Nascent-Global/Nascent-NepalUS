from django.db import models
from django.utils import timezone
from rest_framework import filters, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import PomodoroSession
from .serializers import PomodoroSessionSerializer


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 200


class PomodoroSessionViewSet(viewsets.ModelViewSet):
    """
    CRUD API for PomodoroSession.

    Routes:
    - GET    /pomodoro/sessions/          -> list
    - POST   /pomodoro/sessions/          -> create
    - GET    /pomodoro/sessions/{pk}/     -> retrieve
    - PUT    /pomodoro/sessions/{pk}/     -> update
    - PATCH  /pomodoro/sessions/{pk}/     -> partial_update
    - DELETE /pomodoro/sessions/{pk}/     -> destroy

    Extra actions:
    - GET /pomodoro/sessions/recent/?limit=N      -> most recent N sessions (default 5)
    - GET /pomodoro/sessions/stats/?since=...&until=... -> basic stats (count, avg duration)
    """

    queryset = PomodoroSession.objects.all().order_by("-start_time")
    serializer_class = PomodoroSessionSerializer
    # Allow open access for hackathon MVP; change to IsAuthenticated in production
    permission_classes = [permissions.AllowAny]
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    search_fields = []
    ordering_fields = ["start_time", "duration", "created_at"]
    ordering = ["-start_time"]

    def _parse_int(self, value):
        if value is None:
            return None
        try:
            return int(value)
        except (ValueError, TypeError):
            return None

    def _parse_date(self, value):
        if not value:
            return None
        try:
            # Accept ISO date YYYY-MM-DD
            return timezone.datetime.fromisoformat(value).date()
        except Exception:
            return None

    def get_queryset(self):
        qs = super().get_queryset()
        req = self.request
        since = req.query_params.get("since")
        until = req.query_params.get("until")
        min_dur = self._parse_int(req.query_params.get("min_duration"))
        max_dur = self._parse_int(req.query_params.get("max_duration"))
        completed = req.query_params.get("completed")

        if since:
            sd = self._parse_date(since)
            if sd:
                qs = qs.filter(start_time__date__gte=sd)
        if until:
            ud = self._parse_date(until)
            if ud:
                qs = qs.filter(start_time__date__lte=ud)

        if min_dur is not None:
            qs = qs.filter(duration__gte=min_dur)
        if max_dur is not None:
            qs = qs.filter(duration__lte=max_dur)

        if completed is not None:
            c = str(completed).strip().lower()
            if c in ("1", "true", "yes", "y"):
                qs = qs.filter(completed=True)
            elif c in ("0", "false", "no", "n"):
                qs = qs.filter(completed=False)

        return qs

    def perform_create(self, serializer):
        # If duration not provided but end_time and start_time provided, compute it
        instance = serializer.save()
        if instance.duration is None and instance.start_time and instance.end_time:
            try:
                delta = instance.end_time - instance.start_time
                instance.duration = int(delta.total_seconds())
                instance.save(update_fields=["duration"])
            except Exception:
                pass

    @action(detail=False, methods=["get"], url_path="recent")
    def recent(self, request):
        try:
            limit = int(request.query_params.get("limit", 5))
        except (ValueError, TypeError):
            limit = 5
        qs = self.get_queryset()[:limit]
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"], url_path="stats")
    def stats(self, request):
        """
        Basic statistics endpoint:
        - count
        - avg_duration (seconds, null if none)
        Accepts same `since` and `until` query params as list.
        """
        qs = self.get_queryset()
        count = qs.count()
        avg_duration = qs.aggregate(models_avg=models.Avg("duration"))["models_avg"]
        return Response({"count": count, "avg_duration": avg_duration})
