from django.urls import path
from .views import LaporanCreateView, LaporanListView, ValidasiLaporanView

urlpatterns = [
    path('laporan/', LaporanListView.as_view(), name='laporan-list'),  # GET untuk mengambil daftar laporan
    path('laporan/create/', LaporanCreateView.as_view(), name='laporan-create'),  # POST untuk membuat laporan
    path('laporan/validasi/<int:pk>/', ValidasiLaporanView.as_view(), name='laporan-validasi'),  # POST untuk validasi
]