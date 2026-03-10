import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../data/models/clothing_item_model.dart';
import '../../../../data/models/outfit_model.dart';
import '../../../../features/context_awareness/weather/models/weather_data.dart';
import '../../../../features/outfit_engine/models/scored_outfit.dart';
import '../../../../shared/providers/context_awareness_providers.dart';
import '../../../../shared/providers/home_providers.dart';
import '../../../../shared/providers/outfit_engine_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/context_banner.dart';
import '../widgets/empty_wardrobe_banner.dart';
import '../widgets/outfit_card.dart';
import '../widgets/permission_banner.dart';
import '../widgets/wear_confirm_sheet.dart';

/// Main home screen — shows today's outfit recommendations.
///
/// Displays all outfits generated for today as a scrollable list.
/// Each outfit can be independently marked as worn.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isAddingMore = false;

  @override
  void initState() {
    super.initState();
    // Trigger initial outfit generation.
    ref.read(outfitGenerationResultProvider);
  }

  @override
  Widget build(BuildContext context) {
    final outfitsAsync = ref.watch(todaysOutfitsProvider);
    final weatherAsync = ref.watch(currentWeatherProvider);
    final eventTypeAsync = ref.watch(todaysEventTypeProvider);
    final calendarPermission = ref.watch(calendarPermissionProvider);
    final greeting = ref.watch(homeGreetingProvider);
    final formattedDate = ref.watch(formattedTodayProvider);

    final weather = weatherAsync.asData?.value;
    final eventType =
        eventTypeAsync.asData?.value ?? CalendarEventType.casual;
    final calendarGranted = calendarPermission.asData?.value ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: outfitsAsync.when(
          loading: () => const _HomeLoadingState(),
          error: (err, _) => _HomeErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(todaysOutfitsProvider),
          ),
          data: (outfits) => _HomeBody(
            outfits: outfits,
            weather: weather,
            eventType: eventType,
            isAddingMore: _isAddingMore,
            calendarGranted: calendarGranted,
            greeting: greeting,
            formattedDate: formattedDate,
            onAddMore: _onAddMore,
            onWearToday: _onWearToday,
            onDelete: _onDeleteOutfit,
          ),
        ),
      ),
    );
  }

  Future<void> _onAddMore() async {
    if (_isAddingMore) return;
    setState(() => _isAddingMore = true);
    try {
      await ref.read(regenerateOutfitProvider)();
    } finally {
      if (mounted) setState(() => _isAddingMore = false);
    }
  }

  Future<void> _onDeleteOutfit(OutfitModel outfit) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove outfit?'),
        content: const Text('This outfit will be removed from today\'s list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(outfitRepositoryProvider).delete(outfit.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove outfit — try again')),
      );
    }
  }

  Future<void> _onWearToday(OutfitModel outfit,
      List<ClothingItemModel> items) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WearConfirmSheet(
        scoredOutfit: ScoredOutfit.fromModel(outfit),
        items: items,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(confirmWearUseCaseProvider).call(outfit.id);
      if (!mounted) return;
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
  final List<OutfitModel> outfits;
  final WeatherData? weather;
  final CalendarEventType eventType;
  final bool isAddingMore;
  final bool calendarGranted;
  final String greeting;
  final String formattedDate;
  final VoidCallback onAddMore;
  final Future<void> Function(OutfitModel, List<ClothingItemModel>) onWearToday;
  final Future<void> Function(OutfitModel) onDelete;

  const _HomeBody({
    required this.outfits,
    required this.weather,
    required this.eventType,
    required this.isAddingMore,
    required this.calendarGranted,
    required this.greeting,
    required this.formattedDate,
    required this.onAddMore,
    required this.onWearToday,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wardrobeAsync = ref.watch(allClothingItemsProvider);
    final wardrobe = wardrobeAsync.asData?.value ?? [];
    final itemsById = {for (final i in wardrobe) i.id: i};

    if (outfits.isEmpty) {
      return const Center(child: EmptyWardrobeBanner());
    }

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

          // ③ Section label + add-more button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Outfits",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              isAddingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Generate another outfit',
                      onPressed: onAddMore,
                    ),
            ],
          ),
          const SizedBox(height: 8),

          // ④ Outfit list
          ...outfits.map((outfit) {
            final items = _resolveItems(outfit, itemsById);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Dismissible(
                key: ValueKey(outfit.id),
                direction: outfit.isUserAdded
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                confirmDismiss: (_) async {
                  await onDelete(outfit);
                  // Return false — deletion is handled via the dialog/repo;
                  // the stream re-emits and removes the card reactively.
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.delete_outline,
                      color: Colors.red.shade600, size: 28),
                ),
                child: _OutfitListItem(
                  outfit: outfit,
                  items: items,
                  onWearToday: () => onWearToday(outfit, items),
                  onDelete: () => onDelete(outfit),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<ClothingItemModel> _resolveItems(
      OutfitModel outfit, Map<String, ClothingItemModel> byId) {
    return [
      if (byId[outfit.topId] != null) byId[outfit.topId]!,
      if (byId[outfit.bottomId] != null) byId[outfit.bottomId]!,
      if (byId[outfit.shoesId] != null) byId[outfit.shoesId]!,
      if (outfit.outerwearId != null && byId[outfit.outerwearId!] != null)
        byId[outfit.outerwearId!]!,
    ];
  }
}

// ─── Outfit list item ─────────────────────────────────────────────────────────

/// An [OutfitCard] combined with a per-outfit "Wear This Today" button.
class _OutfitListItem extends StatelessWidget {
  final OutfitModel outfit;
  final List<ClothingItemModel> items;
  final VoidCallback onWearToday;
  final VoidCallback onDelete;

  const _OutfitListItem({
    required this.outfit,
    required this.items,
    required this.onWearToday,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutfitCard(
          scoredOutfit: ScoredOutfit.fromModel(outfit),
          items: items,
          isWorn: outfit.wasWorn,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: outfit.wasWorn ? null : onWearToday,
                icon: Icon(
                    outfit.wasWorn ? Icons.check : Icons.checkroom_outlined),
                label: Text(outfit.wasWorn ? 'Worn Today' : 'Wear This Today'),
              ),
            ),
            const SizedBox(width: 8),
            if (outfit.isUserAdded)
              IconButton.outlined(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                tooltip: 'Remove outfit',
                style: IconButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
          ],
        ),
      ],
    );
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

/// Full-screen shimmer skeleton shown while outfits are being generated.
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
            _shimmerBox(double.infinity, 40, radius: 24),
            const SizedBox(height: 20),
            _shimmerBox(double.infinity, 300, radius: 20),
            const SizedBox(height: 16),
            _shimmerBox(double.infinity, 300, radius: 20),
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
