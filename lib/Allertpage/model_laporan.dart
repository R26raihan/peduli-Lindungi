class Laporan {
  final int id;
  final String namaPelapor;
  final String jenisBencana;
  final String lokasiKejadian;
  final String tanggalKejadian;
  final String deskripsi;
  final String foto;
  final String createdAt;
  final bool? isValidated;  // Ubah menjadi nullable
  final String? validasiDilakukan;
  final String? nomorWa;

  Laporan({
    required this.id,
    required this.namaPelapor,
    required this.jenisBencana,
    required this.lokasiKejadian,
    required this.tanggalKejadian,
    required this.deskripsi,
    required this.foto,
    required this.createdAt,
    this.isValidated,  // Ubah menjadi nullable
    this.validasiDilakukan,
    this.nomorWa,
  });

  factory Laporan.fromJson(Map<String, dynamic> json) {
    return Laporan(
      id: json['id'],
      namaPelapor: json['nama_pelapor'],
      jenisBencana: json['jenis_bencana'],
      lokasiKejadian: json['lokasi_kejadian'],
      tanggalKejadian: json['tanggal_kejadian'],
      deskripsi: json['deskripsi'],
      foto: json['foto'],
      createdAt: json['created_at'],
      isValidated: json['is_validated'],  // Bisa null
      validasiDilakukan: json['validasi_dilakukan'],
      nomorWa: json['nomor_wa'],
    );
  }
}