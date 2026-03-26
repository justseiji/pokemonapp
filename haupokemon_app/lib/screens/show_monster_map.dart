import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
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

  LatLng _currentLocation = const LatLng(0, 0); // Temporary default until GPS locks
  bool _hasLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndMonsters();
  }

  Future<void> _fetchLocationAndMonsters() async {
    _loadMonstersOnMap();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _hasLocation = true;
        });
        _mapController.move(_currentLocation, 16.0);
      }
    } catch (e) {
      // Fails silently; map stays over default coordinates
    }
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
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 3.0, // Start zoomed out globally until GPS fires
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.haupokemon_app',
                ),
                MarkerLayer(
                  markers: [
                    ..._markers,
                    if (_hasLocation)
                      Marker(
                        point: _currentLocation,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 50), // Your actual physical tracker dot
                      ),
                  ],
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _hasLocation ? () => _mapController.move(_currentLocation, 16.0) : null,
        backgroundColor: Colors.white,
        elevation: 4,
        child: Icon(Icons.my_location, color: _hasLocation ? Colors.blue : Colors.grey),
      ),
    );
  }
}
