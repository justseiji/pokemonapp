// dart format off
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_monster_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HAU Pokemon Dashboard')),
      drawer: _buildDrawer(context),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        children: [
          _buildMenuButton(context, 'Players', Icons.people, '/players'),
          _buildMenuButton(context, 'Monsters', Icons.pets, '/monsters'),
          _buildMenuButton(context, 'Catch Radar', Icons.radar, '/catch'),
          _buildMenuButton(context, 'World Map', Icons.map, '/map'),
          _buildMenuButton(
            context,
            'Leaderboard',
            Icons.leaderboard,
            '/leaderboard',
          ),
          _buildMenuButton(context, 'EC2 Manager', Icons.cloud, '/ec2'),
          _buildMenuButton(context, 'About Us', Icons.info, '/about'),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => Navigator.pushNamed(context, route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              String pName = 'Monster Admin';
              if (snapshot.hasData) {
                pName = snapshot.data!.getString('player_name') ?? 'Monster Admin';
              }
              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF386641),
                ),
                accountName: Text(
                  pName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                accountEmail: const Text(''),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Color(0xFFC3E8A7),
                  child: Icon(Icons.catching_pokemon, color: Colors.black, size: 40),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ExpansionTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Manage Monsters'),
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add Monster'),
                contentPadding: const EdgeInsets.only(left: 50),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const EditMonsterScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Monsters'),
                contentPadding: const EdgeInsets.only(left: 50),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/monsters');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete Monsters'),
                contentPadding: const EdgeInsets.only(left: 50),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/monsters');
                },
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.view_list),
            title: const Text('View Top Monster Hunters'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/leaderboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.catching_pokemon),
            title: const Text('Catch Monsters'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/catch');
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Show Monster Map'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/map');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}
