# laporan_admin/routing.py
from django.urls import re_path
from .consumers import LaporanConsumer

websocket_urlpatterns = [
    re_path(r'ws/laporan_notifications/$', LaporanConsumer.as_asgi()),
]
