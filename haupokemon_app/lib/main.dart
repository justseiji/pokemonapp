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
import 'screens/captured_monsters_screen.dart';

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
          seedColor: const Color(0xFFE3350D), // Classic Pokemon Red
          primary: const Color(0xFFE3350D), 
          secondary: const Color(0xFF3B4CCA), // Deep Blue
          tertiary: const Color(0xFFFFDE00), // Pokemon Yellow
          background: const Color(0xFFF7F9FC), // Modern Cool Gray
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE3350D), // Vibrant red app bar
          foregroundColor: Colors.white,
          elevation: 4.0,
          shadowColor: Colors.black26,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.w900, // Thicker font
            fontSize: 24.0,
            letterSpacing: 1.5,
          ),
        ),
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B4CCA), // Blue buttons
            foregroundColor: Colors.white,
            elevation: 4,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Modern rounded
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFDE00), // Iconic Yellow FAB
          foregroundColor: Color(0xFF222224), // Dark icon for contrast
          elevation: 6.0,
          shape: CircleBorder(), // Perfect circles
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))), // Smooth 20 radii
          color: Colors.white,
          surfaceTintColor: Colors.transparent, // Disable M3 tint over cards
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
        '/captured': (context) => const CapturedMonstersScreen(),
      },
    );
  }
}
