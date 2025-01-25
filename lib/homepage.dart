import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'Allertpage/alert.dart';
import 'PemantauanPage/pemantauan.dart';
import './laporanpage/laporan.dart';
import 'airpopulationpage.dart'; 
import 'QuestionPage/question.dart';





void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pemantauan Bencana',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Poppins',
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeContentPage(),
    LaporanPage(),
    PeringatanPage(),
    PemantauanPage(),// Tambahkan BanjirPage ke dalam list _pages
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue.shade800,
            unselectedItemColor: Colors.grey.shade600,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.cloud_outlined),
                activeIcon: Icon(Icons.cloud),
                label: 'Cuaca',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.report_outlined),
                activeIcon: Icon(Icons.report_rounded),
                label: 'Laporan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.warning_outlined),
                activeIcon: Icon(Icons.warning_rounded),
                label: 'Peringatan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor_heart_outlined),
                activeIcon: Icon(Icons.monitor_heart_rounded),
                label: 'Pemantauan',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class HomeContentPage extends StatefulWidget {
  @override
  _HomeContentPageState createState() => _HomeContentPageState();
}

class _HomeContentPageState extends State<HomeContentPage> {
  final String apiKey = '704373e660df98f9b6cdbc73899974b8';
  Position? _currentPosition;
  Map<String, dynamic>? _currentWeather;
  List<Map<String, dynamic>>? _hourlyForecast;
  List<Map<String, dynamic>>? _dailyForecast;
  Map<String, dynamic>? _airPollution;

  // Variabel untuk posisi gambar bot
  Offset _botPosition = Offset(50, 50); // Posisi awal gambar bot

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      await _fetchCurrentWeather(position.latitude, position.longitude);
      await _fetchHourlyForecast(position.latitude, position.longitude);
      await _fetchDailyForecast(position.latitude, position.longitude);
      await _fetchAirPollution(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _fetchCurrentWeather(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _currentWeather = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load current weather data');
    }
  }

  Future<void> _fetchHourlyForecast(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _hourlyForecast = List<Map<String, dynamic>>.from(data['list'].map((item) => {
              'time': item['dt_txt'],
              'temp': item['main']['temp'].toDouble(),
              'condition': item['weather'][0]['main'],
              'description': item['weather'][0]['description'],
            }));
      });
    } else {
      throw Exception('Failed to load hourly forecast data');
    }
  }

  Future<void> _fetchDailyForecast(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/forecast/daily?lat=$lat&lon=$lon&cnt=16&appid=$apiKey&units=metric'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _dailyForecast = List<Map<String, dynamic>>.from(data['list'].map((item) => {
              'date': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
              'temp': item['temp']['day'].toDouble(),
              'condition': item['weather'][0]['main'],
              'description': item['weather'][0]['description'],
            }));
      });
    } else {
      throw Exception('Failed to load daily forecast data');
    }
  }

  Future<void> _fetchAirPollution(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _airPollution = data['list'][0];
      });
    } else {
      throw Exception('Failed to load air pollution data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather Forecast',
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
      body: Stack(
        children: [
          Container(
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
                : _currentWeather == null ||
                        _hourlyForecast == null ||
                        _dailyForecast == null ||
                        _airPollution == null
                    ? Center(
                        child: Text(
                          'Loading weather data...',
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
                            _buildCurrentWeatherCard(),
                            SizedBox(height: 20),
                            _buildHourlyForecast(),
                            SizedBox(height: 20),
                            _buildDailyForecast(),
                            SizedBox(height: 20),
                            _buildAirPollutionCard(),
                          ],
                        ),
                      ),
          ),
          // Widget untuk gambar bot yang dapat digeser
          Positioned(
            left: _botPosition.dx,
            top: _botPosition.dy,
            child: Draggable(
              feedback: Material(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PertanyaanPage(),
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/images/bot.png',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PertanyaanPage(),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/images/bot.png',
                  width: 100,
                  height: 100,
                ),
              ),
              onDragEnd: (details) {
                setState(() {
                  _botPosition = details.offset;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherCard() {
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
              '${_currentWeather!['name']}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Icon(
              _getWeatherIcon(_currentWeather!['weather'][0]['description']),
              size: 60,
              color: Colors.white,
            ),
            SizedBox(height: 10),
            Text(
              '${_currentWeather!['main']['temp']}°C',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '${_currentWeather!['weather'][0]['description']}',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hourly Forecast',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _hourlyForecast!.length,
            itemBuilder: (context, index) {
              final forecast = _hourlyForecast![index];
              return _buildForecastCard(
                forecast['time'],
                forecast['temp'],
                forecast['description'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Forecast',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dailyForecast!.length,
            itemBuilder: (context, index) {
              final forecast = _dailyForecast![index];
              return _buildForecastCard(
                forecast['date'].toString().split(' ')[0],
                forecast['temp'],
                forecast['description'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAirPollutionCard() {
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
              'Air Pollution',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'AQI: ${_airPollution!['main']['aqi']}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              'PM2.5: ${_airPollution!['components']['pm2_5']} µg/m³',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AirPollutionPage(),
                  ),
                );
              },
              child: Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(String time, double temp, String description) {
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
              _getWeatherIcon(description),
              size: 30,
              color: Colors.blue.shade800,
            ),
            SizedBox(height: 10),
            Text(
              '$temp°C',
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

  IconData _getWeatherIcon(String description) {
    switch (description.toLowerCase()) {
      case 'clear sky':
        return Icons.wb_sunny;
      case 'few clouds':
        return Icons.wb_cloudy;
      case 'scattered clouds':
        return Icons.cloud;
      case 'broken clouds':
        return Icons.cloud_queue;
      case 'shower rain':
        return Icons.beach_access;
      case 'rain':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
        return Icons.filter_drama;
      default:
        return Icons.wb_cloudy;
    }
  }
}

