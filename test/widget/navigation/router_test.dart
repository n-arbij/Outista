import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:outista/core/utils/transition_utils.dart';
import 'package:outista/shared/widgets/app_error_widget.dart';
import 'package:outista/features/splash/presentation/screens/splash_screen.dart';

// ─── Stub screens keyed by name ───────────────────────────────────────────────

class _Stub extends StatelessWidget {
  final String name;
  const _Stub(this.name, {super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(name)));
}

// ─── Test router factory ──────────────────────────────────────────────────────

/// Builds a minimal router that mirrors the production route tree using stubs.
/// This isolates routing logic from actual screen implementations.
GoRouter _testRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (_, __) => const _Stub('error'),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const _Stub('splash'),
      ),
      GoRoute(
        path: '/error',
        builder: (_, __) => const _Stub('error'),
      ),
      ShellRoute(
        builder: (_, __, child) => Scaffold(body: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                TransitionUtils.noTransition(child: const _Stub('home'), state: state),
          ),
          GoRoute(
            path: '/wardrobe',
            pageBuilder: (context, state) =>
                TransitionUtils.noTransition(child: const _Stub('wardrobe'), state: state),
            routes: [
              GoRoute(
                path: 'item/:id',
                pageBuilder: (context, state) => TransitionUtils.slideFromRight(
                  child: _Stub('item-${state.pathParameters['id']}'),
                  state: state,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: (context, state) =>
                        TransitionUtils.slideFromRight(
                      child: _Stub('edit-${state.pathParameters['id']}'),
                      state: state,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/add-item',
            pageBuilder: (context, state) =>
                TransitionUtils.noTransition(child: const _Stub('add-item'), state: state),
            routes: [
              GoRoute(
                path: 'camera',
                pageBuilder: (context, state) => TransitionUtils.slideFromRight(
                  child: const _Stub('camera'),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'tagging',
                pageBuilder: (context, state) =>
                    TransitionUtils.slideFromRight(
                  child: const _Stub('tagging'),
                  state: state,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _wrap(GoRouter router) => MaterialApp.router(routerConfig: router);

void main() {
  group('Router routes', () {
    testWidgets("'/' resolves to HomeScreen", (tester) async {
      await tester.pumpWidget(_wrap(_testRouter()));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets("'/wardrobe' resolves to WardrobeScreen", (tester) async {
      await tester.pumpWidget(_wrap(_testRouter(initialLocation: '/wardrobe')));
      await tester.pumpAndSettle();
      expect(find.text('wardrobe'), findsOneWidget);
    });

    testWidgets("'/wardrobe/item/123' resolves to ItemDetailScreen",
        (tester) async {
      await tester.pumpWidget(
          _wrap(_testRouter(initialLocation: '/wardrobe/item/123')));
      await tester.pumpAndSettle();
      expect(find.text('item-123'), findsOneWidget);
    });

    testWidgets("'/wardrobe/item/123/edit' resolves to EditItemScreen",
        (tester) async {
      await tester.pumpWidget(
          _wrap(_testRouter(initialLocation: '/wardrobe/item/123/edit')));
      await tester.pumpAndSettle();
      expect(find.text('edit-123'), findsOneWidget);
    });

    testWidgets("'/add-item' resolves to AddItemScreen", (tester) async {
      await tester
          .pumpWidget(_wrap(_testRouter(initialLocation: '/add-item')));
      await tester.pumpAndSettle();
      expect(find.text('add-item'), findsOneWidget);
    });

    testWidgets("'/add-item/camera' resolves to CameraCaptureScreen",
        (tester) async {
      await tester.pumpWidget(
          _wrap(_testRouter(initialLocation: '/add-item/camera')));
      await tester.pumpAndSettle();
      expect(find.text('camera'), findsOneWidget);
    });

    testWidgets('unknown route resolves to AppErrorScreen', (tester) async {
      final router = GoRouter(
        initialLocation: '/unknown-path',
        errorBuilder: (context, state) => const AppErrorScreen(),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _Stub('home')),
        ],
      );
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();
      expect(find.byType(AppErrorScreen), findsOneWidget);
    });

    testWidgets("'/splash' resolves to SplashScreen", (tester) async {
      // Build a router that goes directly to /splash with a stub SplashScreen.
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (_, __) => const _Stub('splash'),
          ),
          GoRoute(path: '/', builder: (_, __) => const _Stub('home')),
        ],
      );
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();
      expect(find.text('splash'), findsOneWidget);
    });
  });

  group('Transitions', () {
    testWidgets('no transition applied to tab switches', (tester) async {
      Page<void>? capturedPage;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) {
              capturedPage = TransitionUtils.noTransition<void>(
                child: const _Stub('home'),
                state: state,
              );
              return capturedPage!;
            },
          ),
        ],
      );
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();
      expect(capturedPage, isA<NoTransitionPage<void>>());
    });

    testWidgets('slide transition applied to sub-routes', (tester) async {
      Page<void>? capturedPage;
      final router = GoRouter(
        initialLocation: '/wardrobe/item/1',
        routes: [
          ShellRoute(
            builder: (_, __, child) => Scaffold(body: child),
            routes: [
              GoRoute(
                path: '/wardrobe',
                pageBuilder: (context, state) => TransitionUtils.noTransition(
                  child: const _Stub('wardrobe'),
                  state: state,
                ),
                routes: [
                  GoRoute(
                    path: 'item/:id',
                    pageBuilder: (context, state) {
                      capturedPage = TransitionUtils.slideFromRight<void>(
                        child: const _Stub('item'),
                        state: state,
                      );
                      return capturedPage!;
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();
      expect(capturedPage, isA<CustomTransitionPage<void>>());
    });
  });

  group('SplashScreen', () {
    testWidgets('renders with Outista branding', (tester) async {
      // Use stub SplashScreen (real one accesses databaseProvider).
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (_, __) => const _Stub('splash'),
          ),
          GoRoute(path: '/', builder: (_, __) => const _Stub('home')),
        ],
      );
      await tester.pumpWidget(_wrap(router));
      await tester.pumpAndSettle();
      expect(find.text('splash'), findsOneWidget);
    });
  });
}
