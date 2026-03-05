import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:outista/core/services/router_service.dart';
import 'package:outista/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: OutistaApp()));
}

class OutistaApp extends StatelessWidget {
  const OutistaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Outista',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
