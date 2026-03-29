from django.utils import timezone
from rest_framework import filters, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response

from .models import Task
from .serializers import TaskSerializer


# Simple pagination for list endpoints
class StandardResultsSetPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 200


# ViewSet (CRUD + filters + today)
class TaskViewSet(viewsets.ModelViewSet):
    """
    Basic CRUD for Task.

    Supported query params:
      - ?date=YYYY-MM-DD            -> filter tasks by date
      - ?date=today                 -> filter tasks for today (server timezone, UTC-aware)
      - ?task_type=user|recovery    -> filter by task_type
      - ?completed=true|false       -> filter by completion state
      - ?priority=NUMBER            -> filter by priority
      - ?search=TEXT                -> search in title
      - ordering by ?ordering=date,priority,created_at (prefix - for desc)
    """

    queryset = Task.objects.all().order_by("-date", "-created_at")
    serializer_class = TaskSerializer
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.OrderingFilter, filters.SearchFilter]
    search_fields = ["title"]
    ordering_fields = ["date", "priority", "created_at"]
    ordering = ["-date", "-priority"]

    def _parse_bool(self, value):
        if value is None:
            return None
        v = str(value).strip().lower()
        if v in ("1", "true", "yes", "y"):
            return True
        if v in ("0", "false", "no", "n"):
            return False
        return None

    def get_queryset(self):
        qs = super().get_queryset()
        req = self.request
        date_param = req.query_params.get("date")
        task_type = req.query_params.get("task_type")
        completed = req.query_params.get("completed")
        priority = req.query_params.get("priority")

        # Date handling: accept 'today' keyword or ISO date string
        if date_param:
            if date_param.lower() == "today":
                today = timezone.now().date()
                qs = qs.filter(date=today)
            else:
                # allow Django to parse the ISO date string
                qs = qs.filter(date=date_param)

        if task_type:
            qs = qs.filter(task_type=task_type)
        if completed is not None:
            cb = self._parse_bool(completed)
            if cb is True:
                qs = qs.filter(completed=True)
            elif cb is False:
                qs = qs.filter(completed=False)
        if priority is not None:
            try:
                p = int(priority)
            except (ValueError, TypeError):
                p = None
            if p is not None:
                qs = qs.filter(priority=p)

        return qs

    @action(detail=False, methods=["get"])
    def today(self, request):
        """
        Shortcut to list tasks for today's date (server-side date, UTC-aware).
        Optional query params are applied (task_type, completed, etc).
        Example: /tasks/today/?task_type=user&completed=false
        """
        today = timezone.now().date()
        qs = self.get_queryset().filter(date=today)
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=["post"], url_path="toggle-complete")
    def toggle_complete(self, request, pk=None):
        """
        Toggle the `completed` field for a task.
        POST /tasks/{pk}/toggle-complete/
        Returns the updated object.
        """
        task = self.get_object()
        task.completed = not bool(task.completed)
        task.save(update_fields=["completed"])
        serializer = self.get_serializer(task)
        return Response(serializer.data)
