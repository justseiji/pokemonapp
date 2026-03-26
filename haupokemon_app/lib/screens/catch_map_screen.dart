import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:torch_light/torch_light.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class CatchMapScreen extends StatefulWidget {
  const CatchMapScreen({super.key});

  @override
  _CatchMapScreenState createState() => _CatchMapScreenState();
}

class _CatchMapScreenState extends State<CatchMapScreen> {
  bool _isScanning = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Position? _currentPosition;
  String _detectedText = '';

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw Exception('Location permissions denied.');
      }
      if (permission == LocationPermission.deniedForever)
        throw Exception('Permissions permanently denied.');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  Future<void> _scanForMonsters() async {
    setState(() {
      _isScanning = true;
      _detectedText = '';
    });

    try {
      await _fetchCurrentLocation();
      if (_currentPosition == null)
        throw Exception('Could not determine your location.');

      final monsters = await apiService.getList('monsters');

      Map<String, dynamic>? caughtMonster;
      double closestDistance = double.infinity;

      for (var monster in monsters) {
        if (monster['lat'] == null || monster['lng'] == null) continue;
        double mLat = double.tryParse(monster['lat'].toString()) ?? 0;
        double mLng = double.tryParse(monster['lng'].toString()) ?? 0;

        // Dynamically pull the exact DB radius, fallback to 100 if none assigned
        double radius =
            double.tryParse(monster['radius']?.toString() ?? '100.0') ?? 100.0;

        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          mLat,
          mLng,
        );

        if (distance <= radius && distance < closestDistance) {
          closestDistance = distance;
          caughtMonster = monster;
        }
      }

      if (caughtMonster != null) {
        setState(() {
          _detectedText =
              '${caughtMonster!['name']} (${caughtMonster!['type']}) - ${closestDistance.toStringAsFixed(2)} m away';
        });

        await _performCatchSequence(caughtMonster, closestDistance);
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No monsters currently inside your detected radius! Try moving closer to their spawns.',
              ),
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _performCatchSequence(
    Map<String, dynamic> monster,
    double distance,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getInt('player_id');

    if (playerId == null) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please login first.')));
      return;
    }

    if (!kIsWeb) {
      try {
        final isTorchAvailable = await TorchLight.isTorchAvailable();
        if (isTorchAvailable) await TorchLight.enableTorch();
      } catch (_) {}
    }

    try {
      await _audioPlayer.play(
        UrlSource('https://actions.google.com/sounds/v1/alarms/beep_short.ogg'),
      );
    } catch (_) {}

    // Wait slightly to let user read the proximity text, then catch
    await Future.delayed(const Duration(seconds: 4));

    if (!kIsWeb) {
      try {
        await TorchLight.disableTorch();
      } catch (_) {}
    }
    await _audioPlayer.stop();

    try {
      final response = await apiService.postData('game/catch', {
        'player_id': playerId,
        'monster_id': monster['id'],
        'location_id': monster['location_id'],
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Successfully caught ${monster['name']}!',
            ),
          ),
        );
        setState(() {
          _detectedText = ''; // clear out after catching
        });
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to complete the catch action based on location.',
            ),
          ),
        );
    }
  }

  Widget _buildCoordinatorField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.explore, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catch Monsters',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing GPS...')),
              );
              _fetchCurrentLocation();
            },
          ),
        ],
      ),
      backgroundColor: const Color(
        0xFFFCFCF6,
      ), // Warm light background like screenshot
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCoordinatorField(
              'Your Latitude',
              _currentPosition?.latitude.toString() ?? 'Fetching...',
            ),
            const SizedBox(height: 20),
            _buildCoordinatorField(
              'Your Longitude',
              _currentPosition?.longitude.toString() ?? 'Fetching...',
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanForMonsters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B6E3E), // Dark green color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: _isScanning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.radar),
                label: Text(
                  _isScanning ? 'DETECTING...' : 'Detect Monsters',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            if (_detectedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF0F4EC,
                  ), // Very light greenish-gray card
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Monster detected near you!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _detectedText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
