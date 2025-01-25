from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),  # URL untuk admin panel Django
    path('api/', include('laporan.urls')),
    # URL untuk aplikasi laporan
]

# Tambahkan dukungan untuk file media
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)