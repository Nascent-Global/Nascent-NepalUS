from rest_framework import serializers

from .models import BurnoutCause, BurnoutScore, DailyEntry, ScoreLog


# Serializers
class DailyEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyEntry
        fields = [
            "id",
            "date",
            "sleep_hours",
            "work_hours",
            "mood",
            "was_ok",
            "created_at",
            "synced",
        ]
        read_only_fields = ["id", "created_at"]


class BurnoutScoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = BurnoutScore
        fields = [
            "id",
            "date",
            "score",
            "classification",
            "created_at",
            "synced",
        ]
        read_only_fields = ["id", "created_at"]


class BurnoutCauseSerializer(serializers.ModelSerializer):
    class Meta:
        model = BurnoutCause
        fields = ["id", "score", "cause_type"]
        read_only_fields = ["id"]


class ScoreLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ScoreLog
        fields = ["id", "score", "change_amount", "reason", "created_at", "synced"]
        read_only_fields = ["id", "created_at"]
