import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class ShowMonsterMapScreen extends StatefulWidget {
  const ShowMonsterMapScreen({super.key});

  @override
  _ShowMonsterMapScreenState createState() => _ShowMonsterMapScreenState();
}

class _ShowMonsterMapScreenState extends State<ShowMonsterMapScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  bool _isLoading = true;

  static const LatLng _initialPosition = LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _loadMonstersOnMap();
  }

  void _loadMonstersOnMap() async {
    try {
      final monsters = await apiService.getList('monsters');
      if (mounted) {
        setState(() {
          _markers.clear();
          for (var monster in monsters) {
            // Null-check and safe parsing for coordinates
            double lat = 14.5995;
            double lng = 120.9842;
            if (monster['lat'] != null) {
              lat = double.tryParse(monster['lat'].toString()) ?? 14.5995 + (monster['id'] * 0.001);
            }
            if (monster['lng'] != null) {
              lng = double.tryParse(monster['lng'].toString()) ?? 120.9842 + (monster['id'] * 0.001);
            }

            _markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 80,
                height: 80,
                child: Column(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue, size: 40),
                    Text(
                      monster['name'] ?? 'Mystery', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black, backgroundColor: Colors.white70)
                    ),
                  ],
                ),
              ),
            );
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monster World Map')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 14.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.haupokemon_app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
    );
  }
}
