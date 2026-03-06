import 'package:flutter/material.dart';

/// Shows full metadata and photo for a single clothing item.
/// Full implementation in Module 3.
class ItemDetailScreen extends StatelessWidget {
  final String id;

  const ItemDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: Center(child: Text('Module 3 — Item Detail\nid: $id')),
    );
  }
}
