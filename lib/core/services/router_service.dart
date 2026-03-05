import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outista/core/constants/app_routes.dart';
import 'package:outista/shared/widgets/app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const Placeholder(),
        ),
        GoRoute(
          path: AppRoutes.wardrobe,
          builder: (context, state) => const Placeholder(),
        ),
        GoRoute(
          path: AppRoutes.addItem,
          builder: (context, state) => const Placeholder(),
        ),
      ],
    ),
  ],
);
