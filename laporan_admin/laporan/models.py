from django.db import models

class Laporan(models.Model):
    nama_pelapor = models.CharField(max_length=100)
    jenis_bencana = models.CharField(max_length=100)
    lokasi_kejadian = models.CharField(max_length=200)
    tanggal_kejadian = models.DateTimeField()
    deskripsi = models.TextField()
    foto = models.ImageField(upload_to='laporan/')
    created_at = models.DateTimeField(auto_now_add=True)
    is_validated = models.BooleanField(default=False)  # Status validasi laporan
    validasi_dilakukan = models.DateTimeField(null=True, blank=True)  # Waktu validasi oleh admin
    nomor_wa = models.CharField(max_length=15, blank=True, null=True)  # Menambahkan kolom nomor_wa

    def __str__(self):
        return f"Laporan oleh {self.nama_pelapor}"
