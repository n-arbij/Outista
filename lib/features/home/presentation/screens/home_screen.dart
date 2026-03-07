import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../features/context_awareness/weather/models/weather_data.dart';
import '../../../../features/outfit_engine/models/outfit_generation_result.dart';
import '../../../../features/outfit_engine/models/scored_outfit.dart';
import '../../../../shared/providers/context_awareness_providers.dart';
import '../../../../shared/providers/home_providers.dart';
import '../../../../shared/providers/outfit_engine_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/alternatives_carousel.dart';
import '../widgets/context_banner.dart';
import '../widgets/empty_wardrobe_banner.dart';
import '../widgets/outfit_card.dart';
import '../widgets/permission_banner.dart';
import '../widgets/wear_confirm_sheet.dart';

/// Main home screen — shows today's outfit recommendation.
///
/// Consumes [outfitGenerationResultProvider] for the outfit data,
/// [currentWeatherProvider] and [todaysEventTypeProvider] for context badges.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    // Pre-warm the outfit generation future.
    ref.read(outfitGenerationResultProvider);
  }

  @override
  Widget build(BuildContext context) {
    final outfitAsync = ref.watch(outfitGenerationResultProvider);
    final weatherAsync = ref.watch(currentWeatherProvider);
    final eventTypeAsync = ref.watch(todaysEventTypeProvider);
    final calendarPermission = ref.watch(calendarPermissionProvider);
    final greeting = ref.watch(homeGreetingProvider);
    final formattedDate = ref.watch(formattedTodayProvider);
    final isWorn = ref.watch(isOutfitWornProvider);

    final weather = weatherAsync.asData?.value;
    final eventType =
        eventTypeAsync.asData?.value ?? CalendarEventType.casual;
    final calendarGranted = calendarPermission.asData?.value ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: outfitAsync.when(
          loading: () => const _HomeLoadingState(),
          error: (err, _) => _HomeErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(outfitGenerationResultProvider),
          ),
          data: (result) => _HomeBody(
            result: result,
            weather: weather,
            eventType: eventType,
            isWorn: isWorn,
            isRegenerating: _isRegenerating,
            calendarGranted: calendarGranted,
            greeting: greeting,
            formattedDate: formattedDate,
            onRegenerate: _onRegenerate,
            onWearToday: _onWearToday,
          ),
        ),
      ),
    );
  }

  Future<void> _onRegenerate() async {
    if (_isRegenerating) return;
    setState(() => _isRegenerating = true);
    try {
      await ref.read(regenerateOutfitProvider)();
      if (!mounted) return;
      ref.invalidate(outfitGenerationResultProvider);
      ref.read(selectedOutfitProvider.notifier).select(null);
      ref.read(isOutfitWornProvider.notifier).reset();
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  Future<void> _onWearToday(ScoredOutfit scored,
      List<ClothingItemModel> items) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WearConfirmSheet(
        scoredOutfit: scored,
        items: items,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(confirmWearUseCaseProvider).call(scored.outfit.id);
      if (!mounted) return;
      ref.read(isOutfitWornProvider.notifier).markWorn();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outfit confirmed! Have a great day 👗'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save — please try again')),
      );
    }
  }
}

// ─── Main body ────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerWidget {
  final OutfitGenerationResult result;
  final WeatherData? weather;
  final CalendarEventType eventType;
  final bool isWorn;
  final bool isRegenerating;
  final bool calendarGranted;
  final String greeting;
  final String formattedDate;
  final VoidCallback onRegenerate;
  final Future<void> Function(ScoredOutfit, List<ClothingItemModel>) onWearToday;

  const _HomeBody({
    required this.result,
    required this.weather,
    required this.eventType,
    required this.isWorn,
    required this.isRegenerating,
    required this.calendarGranted,
    required this.greeting,
    required this.formattedDate,
    required this.onRegenerate,
    required this.onWearToday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(allClothingItemsProvider);
    final wardrobe = wardrobeAsync.asData?.value ?? [];
    final itemsById = {for (final i in wardrobe) i.id: i};

    final selected = ref.watch(selectedOutfitProvider) ?? result.primary;

    // Initialise selectedOutfitProvider on first data load.
    if (ref.read(selectedOutfitProvider) == null && result.primary != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedOutfitProvider.notifier).select(result.primary);
      });
    }

    if (result.isEmpty) {
      return const Center(child: EmptyWardrobeBanner());
    }

    final scoredOutfit = selected ?? result.primary!;
    final items = _resolveItems(scoredOutfit, itemsById);

    // Alternatives exclude the currently selected outfit.
    final alternatives = result.allOutfits
        .where((o) => o.outfit.id != scoredOutfit.outfit.id)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① Header
          _Header(
            greeting: greeting,
            formattedDate: formattedDate,
            weather: weather,
          ),
          const SizedBox(height: 20),

          // Permission banners
          if (!calendarGranted) ...[
            PermissionBanner(
              permissionType: 'calendar',
              onGrantPressed: () =>
                  ref.read(calendarServiceProvider).requestCalendarPermission(),
            ),
            const SizedBox(height: 12),
          ],

          // ② Context banner
          ContextBanner(weather: weather, eventType: eventType),
          const SizedBox(height: 20),

          // ③ Section label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Outfit",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              isRegenerating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRegenerate,
                    ),
            ],
          ),
          const SizedBox(height: 8),

          // ④ Outfit card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: OutfitCard(
              key: ValueKey(scoredOutfit.outfit.id),
              scoredOutfit: scoredOutfit,
              items: items,
              isWorn: isWorn,
            ),
          ),
          const SizedBox(height: 20),

          // ⑤ Alternatives label
          Text(
            'Alternatives',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),

          // ⑥ Alternatives carousel
          AlternativesCarousel(
            alternatives: alternatives,
            itemsById: itemsById,
            selectedId: scoredOutfit.outfit.id,
            onOutfitSelected: (alt) {
              ref.read(selectedOutfitProvider.notifier).select(alt);
            },
          ),
          const SizedBox(height: 20),

          // ⑦ Wear today button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isWorn ? null : () => onWearToday(scoredOutfit, items),
              icon: Icon(isWorn ? Icons.check : Icons.checkroom_outlined),
              label: Text(isWorn ? 'Worn Today' : 'Wear This Today'),
            ),
          ),
        ],
      ),
    );
  }

  List<ClothingItemModel> _resolveItems(
      ScoredOutfit scored, Map<String, ClothingItemModel> byId) {
    final outfit = scored.outfit;
    return [
      if (byId[outfit.topId] != null) byId[outfit.topId]!,
      if (byId[outfit.bottomId] != null) byId[outfit.bottomId]!,
      if (byId[outfit.shoesId] != null) byId[outfit.shoesId]!,
      if (outfit.outerwearId != null && byId[outfit.outerwearId!] != null)
        byId[outfit.outerwearId!]!,
    ];
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  final String formattedDate;
  final WeatherData? weather;

  const _Header({
    required this.greeting,
    required this.formattedDate,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        if (weather != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              '${weather!.displayTemperature}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

// ─── Loading state ────────────────────────────────────────────────────────────

/// Full-screen shimmer skeleton shown while the outfit is being generated.
class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(160, 22),
                    const SizedBox(height: 6),
                    _shimmerBox(120, 14),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Context banner shimmer
            _shimmerBox(double.infinity, 40, radius: 24),
            const SizedBox(height: 20),
            // Outfit card shimmer
            _shimmerBox(double.infinity, 300, radius: 20),
            const SizedBox(height: 20),
            // Alternatives shimmer
            Row(
              children: [
                _shimmerBox(110, 150, radius: 16),
                const SizedBox(width: 10),
                _shimmerBox(110, 150, radius: 16),
                const SizedBox(width: 10),
                _shimmerBox(110, 150, radius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 8}) {
    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

/// Centered error view with a retry button.
class _HomeErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _HomeErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Could not load outfit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
