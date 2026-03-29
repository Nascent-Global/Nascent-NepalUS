from rest_framework import serializers

from .models import Task


# Serializer
class TaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = Task
        fields = [
            "id",
            "date",
            "title",
            "deadline",
            "priority",
            "completed",
            "task_type",
            "created_at",
            "synced",
        ]
        read_only_fields = ["id", "created_at"]
