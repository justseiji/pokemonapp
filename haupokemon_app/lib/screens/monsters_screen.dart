import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_monster_screen.dart';

class MonstersScreen extends StatefulWidget {
  const MonstersScreen({super.key});

  @override
  _MonstersScreenState createState() => _MonstersScreenState();
}

class _MonstersScreenState extends State<MonstersScreen> {
  List<dynamic> _monsters = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonsters();
  }

  Future<void> _fetchMonsters() async {
    try {
      final monsters = await apiService.getList('monsters');
      setState(() {
        _monsters = monsters;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _deleteMonster(int id) async {
    final confirm = await _showConfirmDialog('Confirm Deletion', 'Are you sure you want to permanently delete this monster?');
    if (!confirm) return;

    try {
      await apiService.deleteData('monsters/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Monster deleted successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Could not delete. ($e)')));
      }
    }
    _fetchMonsters();
  }

  void _navigateToEdit([Map<String, dynamic>? monster]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditMonsterScreen(monster: monster)),
    );
    // Refresh list if the user saved a monster
    if (result == true) {
      _fetchMonsters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Monsters')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMonsters,
              child: _monsters.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: const Center(child: Text('No monsters found. The database is empty.')),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _monsters.length,
                      itemBuilder: (context, index) {
                        final monster = _monsters[index];
                        final String imageUrl = monster['picture_url']?.toString() ?? '';
                        final String formattedUrl = imageUrl.startsWith('/uploads')
                            ? '${ApiService.baseUrl}$imageUrl'
                            : imageUrl;
                        
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: formattedUrl.isNotEmpty 
                                      ? NetworkImage(formattedUrl) 
                                      : null,
                                  child: formattedUrl.isEmpty ? const Icon(Icons.pets, size: 30) : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        monster['name']?.toString() ?? 'Unknown', 
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Type: ${monster['type'] ?? 'Normal'}', style: const TextStyle(fontSize: 14)),
                                      Text('Lat: ${monster['lat'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                                      Text('Lng: ${monster['lng'] ?? 'N/A'}', style: const TextStyle(fontSize: 14)),
                                      Text('Radius: ${monster['radius'] ?? '100'} m', style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.black87),
                                      onPressed: () => _navigateToEdit(monster),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _deleteMonster(monster['id']),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _navigateToEdit(),
      ),
    );
  }
}
