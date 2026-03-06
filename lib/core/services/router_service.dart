import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/wardrobe/presentation/screens/wardrobe_screen.dart';
import '../../features/wardrobe/presentation/screens/item_detail_screen.dart';
import '../../features/wardrobe/presentation/screens/edit_item_screen.dart';
import '../../features/add_item/presentation/screens/add_item_screen.dart';
import '../../features/add_item/presentation/screens/camera_capture_screen.dart';
import '../../features/add_item/presentation/screens/item_tagging_screen.dart';
import '../../shared/widgets/app_shell.dart';

/// Riverpod provider exposing the app's [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.wardrobe,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WardrobeScreen()),
            routes: [
              GoRoute(
                path: AppRoutes.wardrobeItem,
                builder: (context, state) => ItemDetailScreen(
                  id: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: AppRoutes.wardrobeItemEdit,
                    builder: (context, state) => EditItemScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.addItem,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AddItemScreen()),
            routes: [
              GoRoute(
                path: AppRoutes.addItemCamera,
                builder: (context, state) => const CameraCaptureScreen(),
              ),
              GoRoute(
                path: AppRoutes.addItemTagging,
                builder: (context, state) => ItemTaggingScreen(
                  imagePath: state.extra as String,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
