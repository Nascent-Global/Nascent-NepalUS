from django.urls import include, path
from rest_framework import routers

from .views import AlertViewSet

router = routers.DefaultRouter()
router.register(r"", AlertViewSet)

urlpatterns = [
    path("", include(router.urls)),
]
