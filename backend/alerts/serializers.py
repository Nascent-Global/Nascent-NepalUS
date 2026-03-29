from rest_framework import serializers

from .models import Alert


# Serializer
class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = [
            "id",
            "date",
            "type",
            "message",
            "created_at",
            "synced",
        ]
        read_only_fields = ["id", "created_at"]
