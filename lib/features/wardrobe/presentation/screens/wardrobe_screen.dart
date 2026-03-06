import 'package:flutter/material.dart';

/// Wardrobe tab — lists all clothing items with filter controls.
/// Full implementation in Module 3.
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Wardrobe')),
      body: const Center(child: Text('Module 3 — Wardrobe Management')),
    );
  }
}
