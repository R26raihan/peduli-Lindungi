from django.contrib import admin
from django.utils import timezone
from .models import Laporan
from .utils import kirim_notifikasi_whatsapp  # Import fungsi kirim WhatsApp

@admin.register(Laporan)
class LaporanAdmin(admin.ModelAdmin):
    list_display = ('nama_pelapor', 'jenis_bencana', 'lokasi_kejadian', 'tanggal_kejadian', 'created_at', 'is_validated')
    search_fields = ('nama_pelapor', 'jenis_bencana', 'lokasi_kejadian')
    list_filter = ('jenis_bencana', 'created_at')

    actions = ['validate_laporan']  # Menambahkan aksi validasi

    def validate_laporan(self, request, queryset):
        for laporan in queryset:
            if not laporan.is_validated:  # Cek apakah laporan sudah divalidasi
                laporan.is_validated = True
                laporan.validasi_dilakukan = timezone.now()  # Simpan waktu validasi
                laporan.save()

                # Kirim notifikasi WhatsApp jika nomor WhatsApp tersedia
                if laporan.nomor_wa:
                    pesan = (
                        f"Halo {laporan.nama_pelapor},\n\n"
                        f"Laporan Anda tentang {laporan.jenis_bencana} di {laporan.lokasi_kejadian} "
                        f"telah divalidasi. Terima kasih atas partisipasi Anda!"
                    )
                    if kirim_notifikasi_whatsapp(laporan.nomor_wa, pesan):
                        self.message_user(request, f"Notifikasi WhatsApp berhasil dikirim ke {laporan.nomor_wa}.")
                    else:
                        self.message_user(request, f"Gagal mengirim notifikasi WhatsApp ke {laporan.nomor_wa}.", level='error')

                self.message_user(request, f"Laporan oleh {laporan.nomor_wa} berhasil divalidasi.")  # Pesan sukses
            else:
                self.message_user(request, f"Laporan oleh {laporan.nomor_wa} sudah divalidasi sebelumnya.", level='warning')  # Pesan peringatan jika sudah divalidasi
    validate_laporan.short_description = "Validasi Laporan dan Kirim Notifikasi WhatsApp"  # Nama aksi yang ditampilkan di UI admin