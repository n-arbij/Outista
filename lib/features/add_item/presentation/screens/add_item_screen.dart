import 'package:flutter/material.dart';

/// Camera capture and clothing item tagging screen.
/// Full implementation in Module 4.
class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Clothing Item')),
      body: const Center(child: Text('Module 4 — Camera Capture & Tagging')),
    );
  }
}
