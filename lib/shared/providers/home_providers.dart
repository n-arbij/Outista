import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/home/domain/usecases/confirm_wear_usecase.dart';
import '../../features/outfit_engine/models/scored_outfit.dart';
import 'repository_providers.dart';

// ─── Use case ─────────────────────────────────────────────────────────────────

/// Provides [ConfirmWearUseCase] wired to the outfit repository.
final confirmWearUseCaseProvider = Provider<ConfirmWearUseCase>((ref) {
  return ConfirmWearUseCase(
    outfitRepository: ref.watch(outfitRepositoryProvider),
  );
});

// ─── UI state ─────────────────────────────────────────────────────────────────

class _SelectedOutfitNotifier extends Notifier<ScoredOutfit?> {
  @override
  ScoredOutfit? build() => null;

  /// Updates the currently displayed outfit.
  void select(ScoredOutfit? outfit) => state = outfit;
}

/// Holds the currently displayed outfit (primary or a selected alternative).
final selectedOutfitProvider =
    NotifierProvider<_SelectedOutfitNotifier, ScoredOutfit?>(
        _SelectedOutfitNotifier.new);

class _IsOutfitWornNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks today's outfit as confirmed worn.
  void markWorn() => state = true;

  /// Resets worn state (e.g. after regeneration).
  void reset() => state = false;
}

/// Tracks whether today's outfit has been confirmed as worn.
///
/// Resets to `false` on every app restart (not persisted).
final isOutfitWornProvider =
    NotifierProvider<_IsOutfitWornNotifier, bool>(_IsOutfitWornNotifier.new);

// ─── Display providers ────────────────────────────────────────────────────────

/// Returns a dynamic greeting string based on the current hour.
final homeGreetingProvider = Provider<String>((ref) {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning 👋';
  if (hour < 17) return 'Good afternoon 👋';
  if (hour < 21) return 'Good evening 👋';
  return 'Good night 🌙';
});

/// Returns today's date formatted as `'Monday, March 7'`.
final formattedTodayProvider = Provider<String>((ref) {
  return DateFormat('EEEE, MMMM d').format(DateTime.now());
});
