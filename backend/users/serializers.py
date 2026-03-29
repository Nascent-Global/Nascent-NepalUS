from rest_framework import serializers

from .models import UserProfile


# Serializer
class UserProfileSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = UserProfile
        fields = [
            "id",
            "username",
            "email",
            "password",
            "avatar",
            "timezone",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]

    def create(self, validated_data):
        user = UserProfile.objects.create_user(**validated_data)
        return user
