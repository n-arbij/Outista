import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/home/domain/usecases/confirm_wear_usecase.dart';
import 'repository_providers.dart';

// ─── Use case ─────────────────────────────────────────────────────────────────

/// Provides [ConfirmWearUseCase] wired to the outfit repository.
final confirmWearUseCaseProvider = Provider<ConfirmWearUseCase>((ref) {
  return ConfirmWearUseCase(
    outfitRepository: ref.watch(outfitRepositoryProvider),
  );
});

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
