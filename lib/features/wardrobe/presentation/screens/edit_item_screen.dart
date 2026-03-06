import 'package:flutter/material.dart';

/// Edits category, season, occasion, and emotional tag for a clothing item.
/// Full implementation in Module 3.
class EditItemScreen extends StatelessWidget {
  final String id;

  const EditItemScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Center(child: Text('Module 3 — Edit Item\nid: $id')),
    );
  }
}
