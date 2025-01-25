import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TopographyPage extends StatefulWidget {
  const TopographyPage({Key? key}) : super(key: key);

  @override
  _TopographyPageState createState() => _TopographyPageState();
}

class _TopographyPageState extends State<TopographyPage> {
  List<LatLng> landslideProneAreas = [];
  List<LatLng> floodProneAreas = [];

  @override
  void initState() {
    super.initState();
    fetchTopographyData();
  }

  Future<void> fetchTopographyData() async {
    final String apiKey = 'c1f174346349e0e0d1a2e9d4f0bab';
    final String url = 'https://portal.opentopography.org/API/globaldem?demtype=SRTMGL3&south=-7.5&north=-7.0&east=112.8&west=112.5&outputFormat=JSON&APIkey=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          landslideProneAreas = processLandslideData(data);
          floodProneAreas = processFloodData(data);
        });
      } else {
        throw Exception('Gagal mengambil data dari API');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Gagal mengambil data dari API');
    }
  }

  List<LatLng> processLandslideData(Map<String, dynamic> data) {
    // Data dummy untuk area rawan longsor
    return [
      LatLng(-7.25, 112.75),
      LatLng(-7.26, 112.76),
      LatLng(-7.27, 112.74),
    ];
  }

  List<LatLng> processFloodData(Map<String, dynamic> data) {
    // Data dummy untuk area rawan banjir
    return [
      LatLng(-7.28, 112.73),
      LatLng(-7.29, 112.72),
      LatLng(-7.30, 112.71),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Topography'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(-7.2575, 112.7521),
          initialZoom: 10.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          PolygonLayer(
            polygons: [
              if (landslideProneAreas.isNotEmpty)
                Polygon(
                  points: landslideProneAreas,
                  color: Colors.red.withOpacity(0.5),
                  borderColor: Colors.red,
                  borderStrokeWidth: 2,
                ),
              if (floodProneAreas.isNotEmpty)
                Polygon(
                  points: floodProneAreas,
                  color: Colors.blue.withOpacity(0.5),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                ),
            ],
          ),
        ],
      ),
    );
  }
}