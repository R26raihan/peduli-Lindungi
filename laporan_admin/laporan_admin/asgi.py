# laporan_admin/asgi.py
import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.auth import AuthMiddlewareStack
from django.urls import path
from . import consumers  # Impor consumer Anda jika ada

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'laporan_admin.settings')

application = ProtocolTypeRouter({
    "http": get_asgi_application(),  # Untuk HTTP standar
    # Anda dapat menambahkan protokol lainnya, seperti WebSocket
    "websocket": AuthMiddlewareStack(
        URLRouter(
            # Misalnya, jika Anda memiliki routing WebSocket, tambahkan di sini
            # path("ws/some_path/", consumers.YourConsumer.as_asgi()),
        )
    ),
})
