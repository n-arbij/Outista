import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/router_service.dart';
import 'core/services/seed_data.dart';
import 'data/database/app_database.dart';
import 'shared/providers/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler.
  FlutterError.onError = (details) {
    debugPrint('[Outista] Flutter error: ${details.exceptionAsString()}');
  };

  // Global platform/isolate error handler.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Outista] Platform error: $error');
    return true;
  };

  final db = AppDatabase();
  // Warm up the database connection before rendering.
  await db.customSelect('SELECT 1').get();
  
  // Seed sample data
  await SeedData.seedSampleItems(db);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const OutistaApp(),
    ),
  );
}

/// Root widget for the Outista application.
class OutistaApp extends ConsumerWidget {
  const OutistaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Outista',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
