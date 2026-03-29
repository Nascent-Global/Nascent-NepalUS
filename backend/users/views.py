from rest_framework import filters, permissions, viewsets
from rest_framework.pagination import PageNumberPagination

from .models import UserProfile
from .serializers import UserProfileSerializer


# Simple pagination for lists
class StandardResultsSetPagination(PageNumberPagination):
    page_size = 25
    page_size_query_param = "page_size"
    max_page_size = 200


# ModelViewSet for CRUD operations
class UserProfileViewSet(viewsets.ModelViewSet):
    """
    CRUD API for UserProfile.

    Routes:
    - GET    /users/        -> list
    - POST   /users/        -> create
    - GET    /users/{pk}/   -> retrieve
    - PUT    /users/{pk}/   -> update
    - PATCH  /users/{pk}/   -> partial_update
    - DELETE /users/{pk}/   -> destroy
    """

    queryset = UserProfile.objects.all().order_by("-created_at")
    serializer_class = UserProfileSerializer
    def get_permissions(self):
        if self.action == "create":
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]
    pagination_class = StandardResultsSetPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["username"]
    ordering_fields = ["created_at", "username"]
    ordering = ["-created_at"]
