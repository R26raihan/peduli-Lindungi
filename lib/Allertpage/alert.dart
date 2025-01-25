import 'package:flutter/material.dart';
import 'api_service.dart';
import 'model_laporan.dart';

class PeringatanPage extends StatelessWidget {
  final ApiService apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Peringatan'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: FutureBuilder<List<Laporan>>(
        future: apiService.fetchLaporan(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade800,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada data laporan.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Laporan laporan = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto
                        if (laporan.foto != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              laporan.foto,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        SizedBox(height: 12),

                        // Nama Pelapor
                        Text(
                          'Pelapor: ${laporan.namaPelapor}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Jenis Bencana
                        Text(
                          'Jenis Bencana: ${laporan.jenisBencana}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Lokasi Kejadian
                        Text(
                          'Lokasi: ${laporan.lokasiKejadian}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Tanggal Kejadian
                        Text(
                          'Tanggal: ${laporan.tanggalKejadian}',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 8),

                        // Deskripsi
                        Text(
                          'Deskripsi: ${laporan.deskripsi}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Status Validasi
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: laporan.isValidated == true
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            laporan.isValidated == true
                                ? 'Tervalidasi'
                                : 'Belum Tervalidasi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: laporan.isValidated == true
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
