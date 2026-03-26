import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../services/api_service.dart';

class EditMonsterScreen extends StatefulWidget {
  final Map<String, dynamic>? monster;

  const EditMonsterScreen({super.key, this.monster});

  @override
  _EditMonsterScreenState createState() => _EditMonsterScreenState();
}

class _EditMonsterScreenState extends State<EditMonsterScreen> {
  late TextEditingController _nameController;
  late TextEditingController _typeController;
  late TextEditingController _radiusController;
  late TextEditingController _pictureController;

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  LatLng _currentPosition = const LatLng(0, 0); // No Manila fallback
  LatLng _userPhysicalPosition = const LatLng(0, 0);
  bool _hasGPSLock = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.monster?['name']);
    _typeController = TextEditingController(text: widget.monster?['type']);
    _radiusController = TextEditingController(text: widget.monster?['radius']?.toString() ?? '100.00');
    _pictureController = TextEditingController(text: widget.monster?['picture_url']);

    if (widget.monster != null && widget.monster!['lat'] != null && widget.monster!['lng'] != null) {
      _currentPosition = LatLng(
        double.tryParse(widget.monster!['lat'].toString()) ?? 0,
        double.tryParse(widget.monster!['lng'].toString()) ?? 0,
      );
      _getUserPhysicalLocation(false); // Load GPS for crosshair button, keep camera on monster
    } else {
      _getUserPhysicalLocation(true); // Move camera natively to user
    }
  }

  Future<void> _getUserPhysicalLocation(bool moveCamera) async {
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
          _userPhysicalPosition = LatLng(position.latitude, position.longitude);
          _hasGPSLock = true;
          if (moveCamera) {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _mapController.move(_currentPosition, 16.0);
          }
        });
      }
    } catch (e) {}
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _saveMonster() async {
    final confirm = await _showConfirmDialog('Confirm Save', 'Are you sure you want to save this monster?');
    if (!confirm) return;
    
    final data = {
      'name': _nameController.text,
      'type': _typeController.text,
      'radius': double.tryParse(_radiusController.text) ?? 100.0,
      'lat': _currentPosition.latitude.toString(),
      'lng': _currentPosition.longitude.toString(),
      'picture_url': _pictureController.text,
    };

    try {
      if (widget.monster == null) {
        final result = await apiService.postData('monsters', data);
        final newId = result['id'];
        if (_imageBytes != null && _selectedImage != null) {
          await apiService.uploadImage('monsters/$newId/image', _imageBytes!, _selectedImage!.name);
        }
      } else {
        await apiService.putData('monsters/${widget.monster!['id']}', data);
        if (_imageBytes != null && _selectedImage != null) {
          await apiService.uploadImage('monsters/${widget.monster!['id']}/image', _imageBytes!, _selectedImage!.name);
        } else if (_pictureController.text.isEmpty && widget.monster!['picture_url'] != null) {
          await apiService.deleteData('monsters/${widget.monster!['id']}/image');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.monster == null ? 'Monster added!' : 'Monster updated!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double currentRadius = double.tryParse(_radiusController.text) ?? 100.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.monster == null ? 'Add Monster' : 'Edit Monster'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Monster Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Monster Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Spawn Radius (meters)',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 16),
            
            // Map Minimap
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '📍 Tap anywhere on the map to set the exact spawn location',
                style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blueGrey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition,
                        initialZoom: widget.monster == null && !_hasGPSLock ? 3.0 : 16.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _currentPosition = point;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.haupokemon_app',
                        ),
                        if (_hasGPSLock)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _userPhysicalPosition,
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.3), border: Border.all(color: Colors.blue, width: 2)),
                                  child: const Center(child: CircleAvatar(backgroundColor: Colors.blue, radius: 5)),
                                )
                              )
                            ]
                          ),
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _currentPosition,
                              color: Colors.blue.withOpacity(0.3),
                              borderColor: Colors.blue,
                              borderStrokeWidth: 2,
                              useRadiusInMeter: true,
                              radius: currentRadius,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition,
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_hasGPSLock)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: FloatingActionButton.small(
                          onPressed: () {
                            setState(() {
                              _currentPosition = _userPhysicalPosition;
                            });
                            _mapController.move(_userPhysicalPosition, 16.0);
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.my_location, color: Colors.blue),
                        ),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Coordinates Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Latitude: ${_currentPosition.latitude.toStringAsFixed(7)}'),
                    const SizedBox(height: 4),
                    Text('Longitude: ${_currentPosition.longitude.toStringAsFixed(7)}'),
                    const SizedBox(height: 4),
                    Text('Radius: ${currentRadius.toStringAsFixed(2)} meters'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Picture Uploader Widget
            if (_imageBytes != null)
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_imageBytes!, height: 150, fit: BoxFit.cover))
            else if (_pictureController.text.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _pictureController.text.startsWith('/uploads') 
                    ? '${ApiService.baseUrl}${_pictureController.text}' 
                    : _pictureController.text, 
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                ),
              )
            else
              Container(
                height: 150, 
                width: double.infinity, 
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.image, size: 80, color: Colors.grey),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      setState(() {
                        _selectedImage = picked;
                        _imageBytes = bytes;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Image'),
                ),
                if (_imageBytes != null || _pictureController.text.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _imageBytes = null;
                        _pictureController.text = ''; // Clear string to flag deletion
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.white),
                    label: const Text('Remove', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveMonster,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SAVE MONSTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
