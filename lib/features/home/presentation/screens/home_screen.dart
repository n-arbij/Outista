import 'package:flutter/material.dart';

/// Home tab — displays today's outfit suggestion.
/// Full implementation in Module 7.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Outfit')),
      body: const Center(child: Text('Module 7 — Daily Outfit Display')),
    );
  }
}
