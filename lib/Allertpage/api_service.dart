import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model_laporan.dart';  // Pastikan model Laporan sudah dibuat

class ApiService {
  final String baseUrl = 'http://192.168.1.6:8001/api/laporan/';

  Future<List<Laporan>> fetchLaporan() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // Cetak respons JSON untuk debugging
        print('Respons JSON: ${response.body}');

        // Decode respons JSON
        Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Ambil data laporan dari key "results"
        List<dynamic> data = jsonResponse['results'];

        // Ubah data JSON menjadi list objek Laporan
        return data.map((json) => Laporan.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}