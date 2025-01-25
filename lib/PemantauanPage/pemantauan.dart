import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class PemantauanPage extends StatefulWidget {
  @override
  _PemantauanPageState createState() => _PemantauanPageState();
}

class _PemantauanPageState extends State<PemantauanPage> {
  final String apiKey = '704373e660df98f9b6cdbc73899974b8'; // API key OpenWeatherMap
  final String weatherApiKey = '331e5b9cca994fbebe1155720252001'; // API key WeatherAPI
  final String nasaApiKey = 'NJ6KfSbcD8q6PcefysAim2hfpMsh0gLDJqWlaX6J'; // API key NASA Anda
  Position? _currentPosition;
  String _locationName = 'Mengambil lokasi...'; // Nama daerah
  final MapController mapController = MapController();
  Map<String, dynamic>? astronomyData; // Data astronomi dari WeatherAPI

  // Daftar layer cuaca yang tersedia (Weather Maps 1.0)
  final Map<String, String> weatherLayers = {
    'Awan (Clouds)': 'clouds_new',
    'Curah Hujan (Precipitation)': 'precipitation_new',
    'Hujan (Rain)': 'rain_new', // Layer baru
    'Salju (Snow)': 'snow_new', // Layer baru
    'Tekanan Udara (Pressure)': 'pressure_new',
    'Kecepatan Angin (Wind Speed)': 'wind_new',
    'Suhu (Temperature)': 'temp_new',
  };

  // Layer yang dipilih (default: Awan)
  String selectedLayer = 'clouds_new';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Mendapatkan lokasi pengguna
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationName = 'Lokasi tidak aktif';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationName = 'Izin lokasi ditolak';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationName = 'Izin lokasi ditolak permanen';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
      _locationName = 'Lokasi ditemukan';
    });
  }

  // Mengambil data astronomi dari WeatherAPI
  Future<void> _fetchAstronomyData() async {
    if (_currentPosition == null) return;

    final url = Uri.parse(
      'http://api.weatherapi.com/v1/astronomy.json?key=$weatherApiKey&q=${_currentPosition!.latitude},${_currentPosition!.longitude}&dt=2025-01-20',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          astronomyData = json.decode(response.body);
        });
        _showAstronomyDialog(); // Tampilkan dialog setelah data diambil
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengambil data astronomi. Status Code: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  // Menampilkan dialog dengan data astronomi
  void _showAstronomyDialog() {
    if (astronomyData == null) return;

    final astro = astronomyData!['astronomy']['astro'];

    // Penjelasan fase bulan
    String moonPhaseDescription = '';
    switch (astro['moon_phase']) {
      case 'Waning Gibbous':
        moonPhaseDescription = 'Bulan Purnama Menuju Bulan Baru';
        break;
      case 'Waxing Gibbous':
        moonPhaseDescription = 'Bulan Baru Menuju Bulan Purnama';
        break;
      case 'New Moon':
        moonPhaseDescription = 'Bulan Baru';
        break;
      case 'Full Moon':
        moonPhaseDescription = 'Bulan Purnama';
        break;
      default:
        moonPhaseDescription = 'Tidak diketahui';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Data Astronomi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  icon: Icons.wb_sunny,
                  title: 'Matahari Terbit',
                  value: astro['sunrise'],
                ),
                SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.nightlight_round,
                  title: 'Matahari Terbenam',
                  value: astro['sunset'],
                ),
                SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.nights_stay,
                  title: 'Bulan Terbit',
                  value: astro['moonrise'],
                ),
                SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.nightlight_round,
                  title: 'Bulan Terbenam',
                  value: astro['moonset'],
                ),
                SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.brightness_6,
                  title: 'Fase Bulan',
                  value: '${astro['moon_phase']}\n($moonPhaseDescription)',
                ),
                SizedBox(height: 10),
                _buildInfoCard(
                  icon: Icons.brightness_2,
                  title: 'Pencahayaan Bulan',
                  value: '${astro['moon_illumination']}%',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: TextStyle(color: Colors.blue.shade800),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget untuk menampilkan informasi dalam card
  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blue.shade800),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mengambil gambar Earth Imagery dari NASA API
  Future<void> _fetchEarthImagery() async {
    if (_currentPosition == null) return;

    final url = Uri.parse(
      'https://api.nasa.gov/planetary/earth/imagery?lon=${_currentPosition!.longitude}&lat=${_currentPosition!.latitude}&dim=0.15&api_key=$nasaApiKey',
    );

    try {
      // Cek cache
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('earth_imagery');

      if (cachedData != null) {
        // Gunakan data yang sudah di-cache
        final imageBytes = base64Decode(cachedData);
        _showEarthImageryDialog(imageBytes);
        return;
      }

      // Ambil data dari API
      final response = await http.get(url);

      // Debugging: Cetak status code dan respons
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Simpan data biner ke dalam Uint8List
        Uint8List imageBytes = response.bodyBytes;

        // Simpan ke cache
        await prefs.setString('earth_imagery', base64Encode(imageBytes));

        // Tampilkan gambar dalam dialog
        _showEarthImageryDialog(imageBytes);
      } else if (response.statusCode == 429) {
        // Tangani rate limit
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terlalu banyak permintaan. Silakan coba lagi nanti.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengambil gambar Earth Imagery. Status Code: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  // Menampilkan gambar Earth Imagery dalam dialog
  void _showEarthImageryDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Foto Satelit Lokasimu'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6, // Batasi tinggi maksimal
                  ),
                  child: InteractiveViewer(
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.1,
                    maxScale: 4.0,
                    child: Image.memory(imageBytes, fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Mengambil data gempa terkini dari FastAPI
  Future<List<dynamic>> fetchGempaTerkiniData() async {
    final url = Uri.parse('http://192.168.22.64:8000/bmkg/gempa-terkini'); // Endpoint gempa terkini
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Data gempa terkini dari FastAPI: $data"); // Log data yang diterima
        return data['gempa'];
      } else {
        throw Exception('Gagal mengambil data gempa terkini. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Mengambil data auto gempa dari FastAPI
  Future<Map<String, dynamic>> fetchAutoGempaData() async {
    final url = Uri.parse('http://192.168.22.64:8000/bmkg/auto-gempa'); // Endpoint auto gempa
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Data auto gempa dari FastAPI: $data"); // Log data yang diterima
        return data['gempa'];
      } else {
        throw Exception('Gagal mengambil data auto gempa. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Menampilkan dialog dengan detail gempa
  void _showGempaDialog(Map<String, dynamic> gempa) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Informasi Gempa'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tanggal', gempa['Tanggal']),
                _buildInfoRow('Jam', gempa['Jam']),
                _buildInfoRow('Magnitudo', gempa['Magnitude']),
                _buildInfoRow('Kedalaman', gempa['Kedalaman']),
                _buildInfoRow('Wilayah', gempa['Wilayah']),
                _buildInfoRow('Potensi Tsunami', gempa['Potensi']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Mengambil data banjir dari FastAPI
  Future<List<dynamic>> fetchBanjirDataFromFastAPI() async {
    final url = Uri.parse('http://192.168.22.64:8000/banjir'); // Ganti dengan URL FastAPI Anda
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Data banjir dari FastAPI: $data"); // Log data yang diterima
        return data['banjir'];
      } else {
        throw Exception('Gagal mengambil data banjir. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Menampilkan dialog dengan detail banjir
  void _showBanjirDialog(Map<String, dynamic> banjir) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Informasi Bencana'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Lokasi', banjir['lokasi'] ?? 'Tidak tersedia'),
                _buildInfoRow('Tanggal', banjir['tanggal'] ?? 'Tidak tersedia'),
                _buildInfoRow('Desa Terdampak', banjir['desa_terdampak'] ?? 'Tidak tersedia'),
                _buildInfoRow('Keterangan', banjir['keterangan'] ?? 'Tidak tersedia'),
                _buildInfoRow('Penyebab', banjir['penyebab'] ?? 'Tidak tersedia'),
                _buildInfoRow('Kronologis', banjir['kronologis'] ?? 'Tidak tersedia'),
                _buildInfoRow('Sumber', banjir['sumber'] ?? 'Tidak tersedia'),
                _buildInfoRow('Mengungsi', banjir['mengungsi'] ?? 'Tidak tersedia'),
                _buildInfoRow('Rumah Terendam', banjir['rumah_terendam'] ?? 'Tidak tersedia'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Mengambil data pintu air dari FastAPI
  Future<List<dynamic>> fetchPintuAirData() async {
    final url = Uri.parse('http://192.168.22.64:8000/pintu-air');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Data pintu air dari FastAPI: $data"); // Log data yang diterima
        return data['pintu_air'];
      } else {
        throw Exception('Gagal mengambil data pintu air. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Menampilkan dialog dengan detail pintu air
  void _showPintuAirDialog(Map<String, dynamic> pintuAir) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pintuAir['nama_pintu']),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tinggi Air', '${pintuAir['tinggi_air']} cm'),
                _buildInfoRow('Status Siaga', pintuAir['status_siaga']),
                _buildInfoRow('Tanggal', pintuAir['tanggal']),
                _buildInfoRow('Latitude', pintuAir['latitude']),
                _buildInfoRow('Longitude', pintuAir['longitude']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menentukan warna marker berdasarkan status siaga
  Color _getPintuAirColor(String status) {
    if (status.contains("Siaga 1")) {
      return Colors.red;
    } else if (status.contains("Siaga 2")) {
      return Colors.orange;
    } else if (status.contains("Siaga 3")) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  // Widget untuk menampilkan informasi dalam baris
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Peta dengan layer yang dipilih
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : LatLng(-6.2088, 106.8456),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              TileLayer(
                urlTemplate:
                    'https://tile.openweathermap.org/map/$selectedLayer/{z}/{x}/{y}.png?appid=$apiKey',
              ),
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              // Tambahkan marker untuk data gempa terkini
              FutureBuilder<List<dynamic>>(
                future: fetchGempaTerkiniData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return MarkerLayer(markers: []);
                  } else if (snapshot.hasError) {
                    print("Error: ${snapshot.error}"); // Log error
                    return MarkerLayer(markers: []);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print("Data gempa terkini kosong"); // Log jika data kosong
                    return MarkerLayer(markers: []);
                  } else {
                    final gempaList = snapshot.data!;
                    print("Jumlah gempa terkini: ${gempaList.length}"); // Log jumlah gempa
                    return MarkerLayer(
                      markers: gempaList.map((gempa) {
                        final coordinates = gempa['Coordinates'].split(',');
                        final lat = double.tryParse(coordinates[0]);
                        final lon = double.tryParse(coordinates[1]);

                        if (lat == null || lon == null) {
                          print("Koordinat tidak valid: ${gempa['Coordinates']}");
                          return null; // Skip marker jika koordinat tidak valid
                        }

                        print("Marker gempa terkini ditambahkan: Lat=$lat, Lon=$lon"); // Log koordinat marker
                        return Marker(
                          point: LatLng(lat, lon),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showGempaDialog(gempa),
                            child: Image.asset(
                              'assets/images/icons/radargempa.png', // Ikon gempa
                              width: 30,
                              height: 30,
                            ),
                          ),
                        );
                      }).where((marker) => marker != null).cast<Marker>().toList(),
                    );
                  }
                },
              ),
              // Tambahkan marker untuk data auto gempa
              FutureBuilder<Map<String, dynamic>>(
                future: fetchAutoGempaData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return MarkerLayer(markers: []);
                  } else if (snapshot.hasError) {
                    print("Error: ${snapshot.error}"); // Log error
                    return MarkerLayer(markers: []);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print("Data auto gempa kosong"); // Log jika data kosong
                    return MarkerLayer(markers: []);
                  } else {
                    final gempa = snapshot.data!;
                    final coordinates = gempa['Coordinates'].split(',');
                    final lat = double.tryParse(coordinates[0]);
                    final lon = double.tryParse(coordinates[1]);

                    if (lat == null || lon == null) {
                      print("Koordinat tidak valid: ${gempa['Coordinates']}");
                      return MarkerLayer(markers: []);
                    }

                    print("Marker auto gempa ditambahkan: Lat=$lat, Lon=$lon"); // Log koordinat marker
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lon),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showGempaDialog(gempa),
                            child: Image.asset(
                              'assets/images/icons/radargempa.png', // Ikon gempa
                              width: 30,
                              height: 30,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              // Tambahkan marker untuk data banjir
              FutureBuilder<List<dynamic>>(
                future: fetchBanjirDataFromFastAPI(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return MarkerLayer(markers: []);
                  } else if (snapshot.hasError) {
                    print("Error: ${snapshot.error}"); // Log error
                    return MarkerLayer(markers: []);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print("Data banjir kosong"); // Log jika data kosong
                    return MarkerLayer(markers: []);
                  } else {
                    final banjirList = snapshot.data!;
                    print("Jumlah banjir: ${banjirList.length}"); // Log jumlah banjir
                    return MarkerLayer(
                      markers: banjirList.map((banjir) {
                        final lat = double.tryParse(banjir['latitude']);
                        final lon = double.tryParse(banjir['longitude']);

                        if (lat == null || lon == null) {
                          print("Koordinat tidak valid: ${banjir['latitude']}, ${banjir['longitude']}");
                          return null; // Skip marker jika koordinat tidak valid
                        }

                        print("Marker banjir ditambahkan: Lat=$lat, Lon=$lon"); // Log koordinat marker
                        return Marker(
                          point: LatLng(lat, lon),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showBanjirDialog(banjir),
                            child: Image.asset(
                              'assets/images/icons/banjir.png', // Ikon banjir
                              width: 30,
                              height: 30,
                            ),
                          ),
                        );
                      }).where((marker) => marker != null).cast<Marker>().toList(),
                    );
                  }
                },
              ),
              // Tambahkan marker untuk data pintu air
              FutureBuilder<List<dynamic>>(
                future: fetchPintuAirData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return MarkerLayer(markers: []);
                  } else if (snapshot.hasError) {
                    print("Error: ${snapshot.error}"); // Log error
                    return MarkerLayer(markers: []);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    print("Data pintu air kosong"); // Log jika data kosong
                    return MarkerLayer(markers: []);
                  } else {
                    final pintuAirList = snapshot.data!;
                    print("Jumlah pintu air: ${pintuAirList.length}"); // Log jumlah pintu air
                    return MarkerLayer(
                      markers: pintuAirList.map((pintuAir) {
                        final lat = double.tryParse(pintuAir['latitude']);
                        final lon = double.tryParse(pintuAir['longitude']);

                        if (lat == null || lon == null) {
                          print("Koordinat tidak valid: ${pintuAir['latitude']}, ${pintuAir['longitude']}");
                          return null; // Skip marker jika koordinat tidak valid
                        }

                        print("Marker pintu air ditambahkan: Lat=$lat, Lon=$lon"); // Log koordinat marker
                        return Marker(
                          point: LatLng(lat, lon),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showPintuAirDialog(pintuAir),
                            child: Icon(
                              Icons.water_drop,
                              color: _getPintuAirColor(pintuAir['status_siaga']),
                              size: 30,
                            ),
                          ),
                        );
                      }).where((marker) => marker != null).cast<Marker>().toList(),
                    );
                  }
                },
              ),
            ],
          ),
          // Dropdown untuk memilih layer cuaca
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: selectedLayer,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLayer = newValue!;
                  });
                  mapController.move(mapController.camera.center, mapController.camera.zoom);
                },
                items: weatherLayers.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Row(
                      children: [
                        Icon(_getIconForLayer(entry.value), color: Colors.blue.shade800),
                        SizedBox(width: 10),
                        Text(entry.key, style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                isExpanded: true,
                underline: SizedBox(),
              ),
            ),
          ),
          // Tampilkan nama daerah
          Positioned(
            bottom: 160,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                _locationName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Tombol untuk fitur-fitur utama
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tombol Data Astronomi
                FloatingActionButton(
                  onPressed: _fetchAstronomyData,
                  backgroundColor: Colors.blue.shade800,
                  child: Icon(Icons.star, color: Colors.white),
                ),
                // Tombol Earth Imagery
                FloatingActionButton(
                  onPressed: _fetchEarthImagery,
                  backgroundColor: Colors.green.shade800,
                  child: Icon(Icons.satellite, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mendapatkan ikon berdasarkan layer
  IconData _getIconForLayer(String layer) {
    switch (layer) {
      case 'clouds_new':
        return Icons.cloud;
      case 'precipitation_new':
        return Icons.grain;
      case 'rain_new':
        return Icons.water_drop; // Ikon untuk hujan
      case 'snow_new':
        return Icons.ac_unit; // Ikon untuk salju
      case 'pressure_new':
        return Icons.speed;
      case 'wind_new':
        return Icons.air;
      case 'temp_new':
        return Icons.thermostat;
      default:
        return Icons.map;
    }
  }
}