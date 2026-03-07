import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

// ─── Scroll controllers ───────────────────────────────────────────────────────

/// Provides a [ScrollController] per tab, auto-disposed when no longer needed.
///
/// Keys: `'home'`, `'wardrobe'`, `'add_item'`.
final scrollControllerProvider =
    Provider.autoDispose.family<ScrollController, String>((ref, tab) {
  final controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

// ─── Current tab index ────────────────────────────────────────────────────────

/// Notifier for the currently active bottom-nav tab index.
class CurrentTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Updates the active tab to [index].
  void setTab(int index) => state = index;
}

/// Provider tracking the currently active bottom-nav tab index.
///
/// 0 = Home, 1 = Wardrobe, 2 = Add Item.
final currentTabIndexProvider =
    NotifierProvider<CurrentTabIndexNotifier, int>(CurrentTabIndexNotifier.new);

// ─── Wardrobe item count & badge ──────────────────────────────────────────────

/// Provides the current count of clothing items as an [AsyncValue].
///
/// Derived from [allClothingItemsProvider]; updates reactively on every change.
final wardrobeItemCountProvider = Provider<AsyncValue<int>>((ref) {
  return ref
      .watch(allClothingItemsProvider)
      .whenData((items) => items.length);
});

/// `true` when the wardrobe has fewer than 3 items (or is still loading).
///
/// Used by [AppShell] to show a dot badge on the Add Item tab.
final shouldShowAddItemBadgeProvider = Provider<bool>((ref) {
  return ref.watch(wardrobeItemCountProvider).maybeWhen(
        data: (count) => count < 3,
        orElse: () => true,
      );
});
