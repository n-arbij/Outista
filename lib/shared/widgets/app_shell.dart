import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../providers/navigation_providers.dart';

/// Bottom navigation shell wrapping the three main tab routes.
///
/// Features:
/// - Dot badge on Add Item tab when wardrobe has fewer than 3 items
/// - Scroll-to-top on double tap of the currently active tab
/// - NavigationBar visual refinements (border, height, label behavior)
/// - [PageStorage] bucket to enable scroll position persistence in child tabs
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// Shared [PageStorageBucket] for all tab scroll positions.
  final _bucket = PageStorageBucket();

  @override
  Widget build(BuildContext context) {
    final showBadge = ref.watch(shouldShowAddItemBadgeProvider);
    final selectedIndex = _selectedIndex(context);

    return Scaffold(
      body: PageStorage(
        bucket: _bucket,
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _onTap(context, i, selectedIndex),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 200),
          backgroundColor: Colors.white,
          height: 65,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.checkroom_outlined),
              selectedIcon: Icon(Icons.checkroom),
              label: 'Wardrobe',
            ),
            NavigationDestination(
              icon: showBadge
                  ? const Badge(child: Icon(Icons.add_a_photo_outlined))
                  : const Icon(Icons.add_a_photo_outlined),
              selectedIcon: showBadge
                  ? const Badge(child: Icon(Icons.add_a_photo))
                  : const Icon(Icons.add_a_photo),
              label: 'Add Item',
            ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.wardrobe)) return 1;
    if (location.startsWith(AppRoutes.addItem)) return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index, int currentIndex) {
    if (index == currentIndex) {
      _scrollToTop(index);
      return;
    }
    ref.read(currentTabIndexProvider.notifier).setTab(index);
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.wardrobe);
      case 2:
        context.go(AppRoutes.addItem);
    }
  }

  /// Animates the scroll controller for [index] back to the top.
  void _scrollToTop(int index) {
    final controller = ref.read(scrollControllerProvider(_tabName(index)));
    if (controller.hasClients && controller.offset > 0) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _tabName(int index) {
    switch (index) {
      case 1:
        return 'wardrobe';
      case 2:
        return 'add_item';
      default:
        return 'home';
    }
  }
}

