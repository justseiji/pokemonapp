// dart format off
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  _PlayersScreenState createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<dynamic> _players = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    try {
      final players = await apiService.getList('players');
      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<String?> _verifyPlayerPassword(Map<String, dynamic> player) async {
    final passwordController = TextEditingController();
    bool _isVerifying = false;
    
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Security Check: ${player['username']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please re-enter this account\'s original password to authorize modifications.'),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Verify Password'),
                  obscureText: true,
                ),
                if (_isVerifying) const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: _isVerifying ? null : () async {
                  if (passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password is required')));
                    return;
                  }
                  setState(() => _isVerifying = true);
                  try {
                    // Send password dynamically to AWS login route to check authenticity
                    await apiService.login(player['username'].toString(), passwordController.text);
                    Navigator.pop(context, passwordController.text); // Success! Lockpass String Granted.
                  } catch (e) {
                    setState(() => _isVerifying = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect Password! Access Denied.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Verify'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _deletePlayer(Map<String, dynamic> player) async {
    final verifiedPassword = await _verifyPlayerPassword(player);
    if (verifiedPassword == null) return;

    final confirm = await _showConfirmDialog('Confirm Deletion', 'Verification passed! Are you absolutely sure you want to delete this player forever?');
    if (!confirm) return;
    
    try {
      await apiService.deleteData('players/${player['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Could not delete. ($e)')),
        );
      }
    }
    _fetchPlayers();
  }

  void _showPlayerDialog([Map<String, dynamic>? player, String? verifiedPassword]) {
    final playerNameController = TextEditingController(
      text: player?['player_name'],
    );
    final usernameController = TextEditingController(text: player?['username']);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player == null ? 'Add Player' : 'Edit Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: playerNameController,
              decoration: const InputDecoration(
                labelText: 'Player Name (Display Name)',
              ),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (Login Account)',
              ),
            ),
            TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final confirm = await _showConfirmDialog('Confirm Save', 'Are you sure you want to save these changes to the player?');
              if (!confirm) return;

              try {
                final data = {
                  'player_name': playerNameController.text,
                  'username': usernameController.text,
                  'password': passwordController.text.isEmpty && verifiedPassword != null ? verifiedPassword : passwordController.text,
                };
                if (player == null) {
                  await apiService.postData('players', data);
                } else {
                  await apiService.putData('players/${player['id']}', data);
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        player == null
                            ? 'Player added successfully!'
                            : 'Player updated!',
                      ),
                    ),
                  );
                }
                _fetchPlayers();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: Could not save player. ($e)'),
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Players')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPlayers,
              child: _players.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: const Center(
                            child: Text(
                              'No players found. The database is empty.',
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        final player = _players[index];
                        return ListTile(
                          title: Text(
                            player['player_name'] ?? 'Unknown Display Name',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'username: ${player['username'] ?? 'N/A'}',
                          ), //changed sys_user to username
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  final verifiedPassword = await _verifyPlayerPassword(player);
                                  if (verifiedPassword != null) {
                                    _showPlayerDialog(player, verifiedPassword);
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deletePlayer(player),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showPlayerDialog(),
      ),
    );
  }
}
