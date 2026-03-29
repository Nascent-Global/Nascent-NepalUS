from rest_framework import serializers

from .models import BreathingSession


# Serializer
class BreathingSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = BreathingSession
        fields = [
            "id",
            "started_at",
            "duration",
            "completed",
            "created_at",
            "synced",
        ]
        read_only_fields = ["id", "created_at"]
