import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class CapturedMonstersScreen extends StatefulWidget {
  const CapturedMonstersScreen({super.key});

  @override
  _CapturedMonstersScreenState createState() => _CapturedMonstersScreenState();
}

class _CapturedMonstersScreenState extends State<CapturedMonstersScreen> {
  List<dynamic> _catches = [];
  bool _isLoading = true;
  String? _playerId;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final int? id = prefs.getInt('player_id');
    _playerId = id?.toString();
    if (_playerId != null) {
      await _fetchCatches();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCatches() async {
    try {
      final catches = await apiService.getCapturedMonsters(_playerId!);
      if (mounted) {
        setState(() {
          _catches = catches;
        });
      }
    } catch (e) {
      print('Error loading catches: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePhoto(int monsterId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final bytes = await File(image.path).readAsBytes();
      await apiService.uploadImage(
        'monsters/$monsterId/image',
        bytes,
        image.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated successfully!')),
        );
      }
      _fetchCatches();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating photo: $e')));
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteCatch(int catchId) async {
    final confirm = await _showConfirmDialog(
      'Release Monster',
      'Are you sure you want to release this monster? This will reduce your captured count on the leaderboard.',
    );
    if (!confirm) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      await apiService.deleteCatch(catchId.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monster released successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to release monster: $e')),
        );
      }
    }
    _fetchCatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captured Monsters')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCatches,
              child: _catches.isEmpty
                  ? const Center(
                      child: Text(
                        'No caught monsters yet',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _catches.length,
                      itemBuilder: (context, index) {
                        final cat = _catches[index];
                        final String imageUrl =
                            cat['picture_url']?.toString() ?? '';
                        final String formattedUrl =
                            imageUrl.startsWith('/uploads')
                            ? '${ApiService.baseUrl}$imageUrl'
                            : imageUrl;

                        // Parse the date if you want
                        final catchDate = cat['catch_datetime'] != null
                            ? DateTime.tryParse(
                                cat['catch_datetime'].toString(),
                              )
                            : null;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: formattedUrl.isNotEmpty
                                          ? NetworkImage(formattedUrl)
                                          : null,
                                      child: formattedUrl.isEmpty
                                          ? const Icon(
                                              Icons.catching_pokemon,
                                              size: 35,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: -10,
                                      right: -10,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.blue,
                                          ),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(6),
                                          onPressed: () =>
                                              _updatePhoto(cat['id']),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat['name']?.toString() ?? 'Unknown',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Type: ${cat['type'] ?? 'Normal'}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (catchDate != null)
                                        Text(
                                          'Caught on: ${catchDate.year}-${catchDate.month.toString().padLeft(2, '0')}-${catchDate.day.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  tooltip: 'Release Monster',
                                  onPressed: () =>
                                      _deleteCatch(cat['catch_id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
