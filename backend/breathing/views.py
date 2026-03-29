from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import BreathingSession
from .serializers import BreathingSessionSerializer


# ViewSet (basic CRUD + recent)
class BreathingSessionViewSet(viewsets.ModelViewSet):
    queryset = BreathingSession.objects.all().order_by("-started_at")
    serializer_class = BreathingSessionSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        since = self.request.query_params.get("since")
        until = self.request.query_params.get("until")

        if since:
            qs = qs.filter(started_at__date__gte=since)
        if until:
            qs = qs.filter(started_at__date__lte=until)

        return qs

    @action(detail=False, methods=["get"])
    def recent(self, request):
        try:
            limit = int(request.query_params.get("limit", 5))
        except ValueError:
            limit = 5

        sessions = self.get_queryset()[:limit]
        serializer = self.get_serializer(sessions, many=True)
        return Response(serializer.data)
