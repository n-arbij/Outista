import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outista/core/constants/app_routes.dart';

// Module 8 — Bottom navigation shell
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.checkroom_outlined), label: 'Wardrobe'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Add'),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.wardrobe)) return 1;
    if (location.startsWith(AppRoutes.addItem)) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.wardrobe);
      case 2:
        context.go(AppRoutes.addItem);
    }
  }
}
