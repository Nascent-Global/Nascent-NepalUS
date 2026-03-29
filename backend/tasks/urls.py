from django.urls import include, path
from rest_framework import routers

from .views import TaskViewSet

# Router & URLConf for inclusion
router = routers.DefaultRouter()
router.register(r"planner", TaskViewSet, basename="task")

urlpatterns = [
    path("", include(router.urls)),
]
