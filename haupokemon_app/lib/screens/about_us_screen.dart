import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Us')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png',
              ), // Pikachu!
            ),
            const SizedBox(height: 20),
            Text(
              'HAUPokemon Monster\'s App',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Version 1.0.0',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const Text(
              'This application was created as a final project to demonstrate full-stack cloud infrastructure and a mobile frontend. Features include Player and Monster CRUD, a Map-based catching system, a leaderboard, and AWS EC2 Automation directly from the app.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            const Text(
              '© 2026 HAUPokemon Team. All Rights Reserved.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
