from rest_framework import serializers

from .models import UserProfile


# Serializer
class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            "id",
            "username",
            "avatar",
            "timezone",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]
