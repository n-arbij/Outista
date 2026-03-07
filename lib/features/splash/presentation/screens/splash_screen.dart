import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/providers/database_provider.dart';

/// Branded splash screen shown on first launch.
///
/// Waits a minimum of 1500 ms for branding, warms up the database,
/// then navigates to the home screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _launch();
  }

  Future<void> _launch() async {
    final db = ref.read(databaseProvider);
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1500)),
      db.customSelect('SELECT 1').get(),
    ]);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checkroom, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Outista',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your daily outfit assistant',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
