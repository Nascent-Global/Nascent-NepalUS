from rest_framework import serializers

from .models import PomodoroSession


class PomodoroSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PomodoroSession
        fields = [
            "id",
            "start_time",
            "end_time",
            "duration",
            "completed",
            "created_at",
            "synced",
        ]
        read_only_fields = ["id", "created_at"]
