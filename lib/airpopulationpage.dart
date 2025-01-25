import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AirPollutionPage extends StatefulWidget {
  @override
  _AirPollutionPageState createState() => _AirPollutionPageState();
}

class _AirPollutionPageState extends State<AirPollutionPage> {
  final String apiKey = '704373e660df98f9b6cdbc73899974b8'; 
  Position? _currentPosition;
  Map<String, dynamic>? _currentAirPollution;
  List<Map<String, dynamic>>? _forecastAirPollution;
  List<Map<String, dynamic>>? _historicalAirPollution;
  String _locationName = 'Mengambil lokasi...'; // Variabel untuk nama daerah
  final String _cacheKey = 'air_pollution_cache';
  final int _cacheDuration = 5 * 60 * 1000; // 5 menit dalam milidetik

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      await _loadAirPollutionData(position.latitude, position.longitude);
    } catch (e) {
      print('Error mendapatkan lokasi: $e');
    }
  }

  Future<String> _getLocationName(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&limit=1&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        return data[0]['name']; // Ambil nama daerah dari respons
      }
    }
    return 'Lokasi Tidak Diketahui'; // Fallback jika tidak ada data
  }

  Future<void> _loadAirPollutionData(double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cacheKey);

    if (cachedData != null) {
      final cache = json.decode(cachedData);
      final lastUpdated = cache['lastUpdated'];
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastUpdated <= _cacheDuration) {
        // Gunakan data cache jika masih valid
        setState(() {
          _currentAirPollution = cache['currentAirPollution'];
          _forecastAirPollution = List<Map<String, dynamic>>.from(cache['forecastAirPollution']);
          _historicalAirPollution = List<Map<String, dynamic>>.from(cache['historicalAirPollution']);
          _locationName = cache['locationName']; // Ambil nama daerah dari cache
        });
        return;
      }
    }

    // Jika cache tidak ada atau sudah kadaluarsa, ambil data baru
    final locationName = await _getLocationName(lat, lon); // Ambil nama daerah
    await _fetchCurrentAirPollution(lat, lon);
    await _fetchForecastAirPollution(lat, lon);

    // Ambil historical data (contoh: 7 hari terakhir)
    final now = DateTime.now();
    final start = now.subtract(Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
    final end = now.millisecondsSinceEpoch ~/ 1000;
    await _fetchHistoricalAirPollution(lat, lon, start, end);

    // Simpan data ke cache
    final cacheData = {
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      'currentAirPollution': _currentAirPollution,
      'forecastAirPollution': _forecastAirPollution,
      'historicalAirPollution': _historicalAirPollution,
      'locationName': locationName, // Simpan nama daerah ke cache
    };
    prefs.setString(_cacheKey, json.encode(cacheData));

    setState(() {
      _locationName = locationName; // Update nama daerah di state
    });
  }

  Future<void> _fetchCurrentAirPollution(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _currentAirPollution = data['list'][0];
      });
    } else {
      throw Exception('Gagal memuat data polusi udara saat ini');
    }
  }

  Future<void> _fetchForecastAirPollution(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution/forecast?lat=$lat&lon=$lon&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _forecastAirPollution = List<Map<String, dynamic>>.from(data['list'].map((item) => {
              'dt': item['dt'],
              'aqi': item['main']['aqi'],
              'components': item['components'],
            }));
      });
    } else {
      throw Exception('Gagal memuat data prakiraan polusi udara');
    }
  }

  Future<void> _fetchHistoricalAirPollution(double lat, double lon, int start, int end) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution/history?lat=$lat&lon=$lon&start=$start&end=$end&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _historicalAirPollution = List<Map<String, dynamic>>.from(data['list'].map((item) => {
              'dt': item['dt'],
              'aqi': item['main']['aqi'],
              'components': item['components'],
            }));
      });
    } else {
      throw Exception('Gagal memuat data historis polusi udara');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Data Polusi Udara',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _currentPosition == null
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.blue.shade800,
                ),
              )
            : _currentAirPollution == null || _forecastAirPollution == null || _historicalAirPollution == null
                ? Center(
                    child: Text(
                      'Memuat data polusi udara...',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCurrentAirPollutionCard(),
                        SizedBox(height: 20),
                        _buildForecastAirPollutionCard(),
                        SizedBox(height: 20),
                        _buildHistoricalAirPollutionCard(),
                        SizedBox(height: 20),
                        _buildAQIScaleCard(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCurrentAirPollutionCard() {
    final aqi = _currentAirPollution!['main']['aqi'];
    final pm25 = _currentAirPollution!['components']['pm2_5'];
    final pm10 = _currentAirPollution!['components']['pm10'];

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_getAQIColor(aqi), _getAQIColor(aqi).withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Polusi Udara Saat Ini di $_locationName', // Tampilkan nama daerah
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Icon(
              Icons.air,
              size: 50,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              'AQI: $aqi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'PM2.5: $pm25 µg/m³',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              'PM10: $pm10 µg/m³',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _getAQIDescription(aqi),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastAirPollutionCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Prakiraan Polusi Udara',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _forecastAirPollution!.length,
                itemBuilder: (context, index) {
                  final forecast = _forecastAirPollution![index];
                  return _buildForecastCard(
                    DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000).toString().split(' ')[0],
                    forecast['aqi'].toString(),
                    'AQI: ${forecast['aqi']}',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalAirPollutionCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Data Historis Polusi Udara',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _historicalAirPollution!.length,
                itemBuilder: (context, index) {
                  final historical = _historicalAirPollution![index];
                  return _buildForecastCard(
                    DateTime.fromMillisecondsSinceEpoch(historical['dt'] * 1000).toString().split(' ')[0],
                    historical['aqi'].toString(),
                    'AQI: ${historical['aqi']}',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAQIScaleCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skala Indeks Kualitas Udara (AQI)',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Berikut adalah skala AQI beserta konsentrasi polutan dalam μg/m³:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            _buildAQIItem('Baik (1)', 'SO2 [0; 20), NO2 [0; 40), PM10 [0; 20), PM2.5 [0; 10), O3 [0; 60), CO [0; 4400)', Colors.green),
            _buildAQIItem('Cukup (2)', 'SO2 [20; 80), NO2 [40; 70), PM10 [20; 50), PM2.5 [10; 25), O3 [60; 100), CO [4400; 9400)', Colors.yellow),
            _buildAQIItem('Sedang (3)', 'SO2 [80; 250), NO2 [70; 150), PM10 [50; 100), PM2.5 [25; 50), O3 [100; 140), CO [9400-12400)', Colors.orange),
            _buildAQIItem('Buruk (4)', 'SO2 [250; 350), NO2 [150; 200), PM10 [100; 200), PM2.5 [50; 75), O3 [140; 180), CO [12400; 15400)', Colors.red),
            _buildAQIItem('Sangat Buruk (5)', 'SO2 ⩾350, NO2 ⩾200, PM10 ⩾200, PM2.5 ⩾75, O3 ⩾180, CO ⩾15400', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildAQIItem(String title, String description, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: color.withOpacity(0.8), // Warna latar belakang dengan opacity
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(String time, String temp, String description) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: EdgeInsets.only(right: 10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 10),
            Icon(
              Icons.air,
              size: 30,
              color: Colors.blue.shade800,
            ),
            SizedBox(height: 10),
            Text(
              temp,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAQIColor(int aqi) {
    if (aqi == 1) return Colors.green;
    if (aqi == 2) return Colors.yellow;
    if (aqi == 3) return Colors.orange;
    if (aqi == 4) return Colors.red;
    if (aqi == 5) return Colors.purple;
    return Colors.grey;
  }

  String _getAQIDescription(int aqi) {
    if (aqi == 1) return 'Baik: Kualitas udara memuaskan, dan polusi udara menimbulkan sedikit atau tidak ada risiko.';
    if (aqi == 2) return 'Cukup: Kualitas udara dapat diterima. Namun, mungkin ada risiko bagi beberapa orang, terutama mereka yang sensitif terhadap polusi udara.';
    if (aqi == 3) return 'Sedang: Anggota kelompok sensitif mungkin mengalami efek kesehatan. Masyarakat umum cenderung tidak terpengaruh.';
    if (aqi == 4) return 'Buruk: Semua orang mungkin mulai merasakan efek kesehatan; anggota kelompok sensitif mungkin mengalami efek kesehatan yang lebih serius.';
    if (aqi == 5) return 'Sangat Buruk: Peringatan kesehatan tentang kondisi darurat. Seluruh populasi lebih mungkin terpengaruh.';
    return 'Tidak Diketahui: Tidak ada data yang tersedia.';
  }
}