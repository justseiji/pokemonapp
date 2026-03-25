import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/players_screen.dart';
import 'screens/monsters_screen.dart';
import 'screens/catch_map_screen.dart';
import 'screens/show_monster_map.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/ec2_management_screen.dart';
import 'screens/about_us_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HauPokemonApp()));
}

class HauPokemonApp extends StatelessWidget {
  const HauPokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HAUPokemon Monsters App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          primary: Colors.red, // Pokeball Red
          secondary: Colors.yellow, // Pikachu Yellow
          tertiary: Colors.blue, // Squirtle Blue
          background: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/', // Secure Login Path
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/players': (context) => const PlayersScreen(),
        '/monsters': (context) => const MonstersScreen(),
        '/catch': (context) => const CatchMapScreen(),
        '/map': (context) => const ShowMonsterMapScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/ec2': (context) => const Ec2ManagementScreen(),
        '/about': (context) => const AboutUsScreen(),
      },
    );
  }
}
