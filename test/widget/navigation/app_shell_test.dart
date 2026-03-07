import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:outista/shared/providers/navigation_providers.dart';
import 'package:outista/shared/providers/repository_providers.dart';
import 'package:outista/shared/widgets/app_shell.dart';

// ─── Stub tab screens ─────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.watch(scrollControllerProvider('home'));
    return Scaffold(
      body: ListView.builder(
        controller: ctrl,
        itemCount: 30,
        itemBuilder: (_, i) => SizedBox(height: 80, child: Text('item $i')),
      ),
    );
  }
}

class _WardrobeTab extends StatelessWidget {
  const _WardrobeTab();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Wardrobe')));
}

class _AddItemTab extends StatelessWidget {
  const _AddItemTab();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Add Item')));
}

// ─── Test app builder ─────────────────────────────────────────────────────────

Widget _buildApp({bool showBadge = false}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _HomeTab()),
          GoRoute(path: '/wardrobe', builder: (_, __) => const _WardrobeTab()),
          GoRoute(path: '/add-item', builder: (_, __) => const _AddItemTab()),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      shouldShowAddItemBadgeProvider.overrideWith((ref) => showBadge),
      allClothingItemsProvider.overrideWith((ref) => Stream.value([])),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('AppShell', () {
    testWidgets('renders HomeScreen at route /', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();
      expect(find.text('item 0'), findsOneWidget);
    });

    testWidgets('renders WardrobeScreen at route /wardrobe', (tester) async {
      final router = GoRouter(
        initialLocation: '/wardrobe',
        routes: [
          ShellRoute(
            builder: (_, __, child) => AppShell(child: child),
            routes: [
              GoRoute(path: '/', builder: (_, __) => const _HomeTab()),
              GoRoute(
                  path: '/wardrobe', builder: (_, __) => const _WardrobeTab()),
              GoRoute(
                  path: '/add-item', builder: (_, __) => const _AddItemTab()),
            ],
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          shouldShowAddItemBadgeProvider.overrideWith((ref) => false),
          allClothingItemsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Wardrobe'), findsWidgets);
    });

    testWidgets('renders AddItemScreen at route /add-item', (tester) async {
      final router = GoRouter(
        initialLocation: '/add-item',
        routes: [
          ShellRoute(
            builder: (_, __, child) => AppShell(child: child),
            routes: [
              GoRoute(path: '/', builder: (_, __) => const _HomeTab()),
              GoRoute(
                  path: '/wardrobe', builder: (_, __) => const _WardrobeTab()),
              GoRoute(
                  path: '/add-item', builder: (_, __) => const _AddItemTab()),
            ],
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          shouldShowAddItemBadgeProvider.overrideWith((ref) => false),
          allClothingItemsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Add Item'), findsWidgets);
    });

    testWidgets('tapping wardrobe tab navigates to /wardrobe', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wardrobe'));
      await tester.pumpAndSettle();

      expect(find.text('Wardrobe'), findsWidgets);
    });

    testWidgets('tapping home tab navigates back to /', (tester) async {
      final router = GoRouter(
        initialLocation: '/wardrobe',
        routes: [
          ShellRoute(
            builder: (_, __, child) => AppShell(child: child),
            routes: [
              GoRoute(path: '/', builder: (_, __) => const _HomeTab()),
              GoRoute(
                  path: '/wardrobe', builder: (_, __) => const _WardrobeTab()),
              GoRoute(
                  path: '/add-item', builder: (_, __) => const _AddItemTab()),
            ],
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          shouldShowAddItemBadgeProvider.overrideWith((ref) => false),
          allClothingItemsProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('item 0'), findsOneWidget);
    });

    testWidgets('badge shown on Add Item tab when showBadge is true',
        (tester) async {
      await tester.pumpWidget(_buildApp(showBadge: true));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsWidgets);
    });

    testWidgets('badge hidden when showBadge is false', (tester) async {
      await tester.pumpWidget(_buildApp(showBadge: false));
      await tester.pumpAndSettle();
      expect(find.byType(Badge), findsNothing);
    });

    testWidgets('double tapping active tab triggers scroll to top',
        (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Scroll the list down.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Retrieve the scroll controller via the provider using an element
      // that's actually inside the ProviderScope tree.
      final homeElement = tester.element(find.byType(_HomeTab));
      final container = ProviderScope.containerOf(homeElement);
      final ctrl = container.read(scrollControllerProvider('home'));
      expect(ctrl.offset, greaterThan(0));

      // Tap the active Home tab (double tap = first tap is already on Home).
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(ctrl.offset, 0.0);
    });
  });
}
