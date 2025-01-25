from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics
from .models import Laporan
from .serializers import LaporanSerializer

# View untuk membuat laporan (POST)
class LaporanCreateView(APIView):
    def post(self, request, *args, **kwargs):
        serializer = LaporanSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# View untuk mengambil daftar laporan (GET)
class LaporanListView(generics.ListAPIView):
    queryset = Laporan.objects.all()
    serializer_class = LaporanSerializer

# View untuk validasi laporan (POST)
class ValidasiLaporanView(APIView):
    def post(self, request, pk, *args, **kwargs):
        try:
            laporan = Laporan.objects.get(pk=pk)
        except Laporan.DoesNotExist:
            return Response({'detail': 'Laporan tidak ditemukan'}, status=status.HTTP_404_NOT_FOUND)

        # Periksa apakah laporan sudah divalidasi atau belum
        if laporan.is_verified:
            return Response({'detail': 'Laporan sudah divalidasi'}, status=status.HTTP_400_BAD_REQUEST)

        # Set status validasi menjadi True
        laporan.is_verified = True
        laporan.save()

        # Kirim notifikasi kepada user jika diperlukan
        self.send_notification_to_user(laporan)

        # Kembalikan respons laporan yang telah divalidasi
        return Response(LaporanSerializer(laporan).data, status=status.HTTP_200_OK)

    def send_notification_to_user(self, laporan):
        # Di sini Anda dapat menambahkan logika untuk mengirimkan pemberitahuan kepada pengguna
        # Contohnya, bisa menggunakan email atau notifikasi push ke aplikasi Flutter.
        print(f"Notifikasi: Laporan oleh {laporan.nama_pelapor} telah divalidasi!")