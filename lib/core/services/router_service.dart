import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_routes.dart';
import '../utils/transition_utils.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/wardrobe/presentation/screens/wardrobe_screen.dart';
import '../../features/wardrobe/presentation/screens/item_detail_screen.dart';
import '../../features/wardrobe/presentation/screens/edit_item_screen.dart';
import '../../features/add_item/presentation/screens/add_item_screen.dart';
import '../../features/add_item/presentation/screens/camera_capture_screen.dart';
import '../../features/add_item/presentation/screens/item_tagging_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/app_error_widget.dart';

/// Riverpod provider exposing the app's [GoRouter] instance.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => const AppErrorScreen(),
    redirect: (context, state) {
      // Navigation is always permitted — DB is initialized in main() before runApp.
      return null;
    },
    routes: [
      // ── Standalone routes (no bottom nav shell) ──────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/error',
        builder: (context, state) => const AppErrorScreen(),
      ),
      // ── Main shell with bottom navigation ────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => TransitionUtils.noTransition(
              child: const HomeScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: AppRoutes.wardrobe,
            pageBuilder: (context, state) => TransitionUtils.noTransition(
              child: const WardrobeScreen(),
              state: state,
            ),
            routes: [
              GoRoute(
                path: AppRoutes.wardrobeItem,
                pageBuilder: (context, state) => TransitionUtils.slideFromRight(
                  child: ItemDetailScreen(id: state.pathParameters['id']!),
                  state: state,
                ),
                routes: [
                  GoRoute(
                    path: AppRoutes.wardrobeItemEdit,
                    pageBuilder: (context, state) =>
                        TransitionUtils.slideFromRight(
                      child: EditItemScreen(id: state.pathParameters['id']!),
                      state: state,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.addItem,
            pageBuilder: (context, state) => TransitionUtils.noTransition(
              child: const AddItemScreen(),
              state: state,
            ),
            routes: [
              GoRoute(
                path: AppRoutes.addItemCamera,
                pageBuilder: (context, state) => TransitionUtils.slideFromRight(
                  child: const CameraCaptureScreen(),
                  state: state,
                ),
              ),
              GoRoute(
                path: AppRoutes.addItemTagging,
                pageBuilder: (context, state) {
                  final imagePath = state.extra;
                  if (imagePath is! String) {
                    // Redirect to parent if extra is missing or invalid.
                    return TransitionUtils.noTransition(
                      child: const AddItemScreen(),
                      state: state,
                    );
                  }
                  return TransitionUtils.slideFromRight(
                    child: ItemTaggingScreen(imagePath: imagePath),
                    state: state,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
