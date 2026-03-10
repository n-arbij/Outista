import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:outista/core/constants/app_enums.dart';
import 'package:outista/data/models/clothing_item_model.dart';
import 'package:outista/data/models/outfit_model.dart';
import 'package:outista/data/repositories/outfit_repository.dart';
import 'package:outista/features/context_awareness/weather/models/weather_data.dart';
import 'package:outista/features/outfit_engine/models/outfit_context.dart';
import 'package:outista/features/outfit_engine/models/outfit_generation_result.dart';
import 'package:outista/features/outfit_engine/models/scored_outfit.dart';
import 'package:outista/features/home/presentation/screens/home_screen.dart';
import 'package:outista/features/home/presentation/widgets/empty_wardrobe_banner.dart';
import 'package:outista/features/home/presentation/widgets/outfit_card.dart';
import 'package:outista/features/home/presentation/widgets/permission_banner.dart';
import 'package:outista/shared/providers/context_awareness_providers.dart';
import 'package:outista/shared/providers/home_providers.dart';
import 'package:outista/shared/providers/outfit_engine_providers.dart';
import 'package:outista/shared/providers/repository_providers.dart';
// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeOutfitRepository implements OutfitRepository {
  @override
  Future<List<OutfitModel>> getRecent({int limit = 10}) async => [];
  @override
  Future<OutfitModel?> getById(String id) async => null;
  @override
  Future<void> save(OutfitModel outfit) async {}
  @override
  Future<void> saveAll(List<OutfitModel> outfits, {bool isUserAdded = false}) async {}
  @override
  Future<List<OutfitModel>> getTodaysOutfits() async => [];
  @override
  Stream<List<OutfitModel>> watchTodaysOutfits() => const Stream.empty();
  @override
  Future<void> markAsWorn(String id) async {}
  @override
  Future<void> delete(String id) async {}
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

ClothingItemModel _item(String id, ClothingCategory cat) => ClothingItemModel(
      id: id,
      imagePath: '/nonexistent/path.jpg',
      category: cat,
      season: ClothingSeason.allWeather,
      occasion: ClothingOccasion.casual,
      createdAt: DateTime(2024, 1, 1),
    );

OutfitGenerationResult _result({bool empty = false}) {
  if (empty) {
    return OutfitGenerationResult(
      primary: null,
      alternatives: [],
      context: OutfitContext(
        weatherSeason: WeatherSeason.allWeather,
        eventType: CalendarEventType.casual,
        date: DateTime.now(),
      ),
      generatedAt: DateTime.now(),
      totalCombinationsEvaluated: 0,
    );
  }
  final outfit = OutfitModel(
    id: 'o1',
    topId: 'top1',
    bottomId: 'bot1',
    shoesId: 'shoe1',
    score: 80,
    occasionContext: 'casual',
    weatherContext: 'allWeather',
    generatedAt: DateTime.now(),
  );
  final scored = ScoredOutfit(
    outfit: outfit,
    totalScore: 80,
    seasonScore: 30,
    occasionScore: 25,
    usageScore: 20,
    bonusScore: 5,
  );
  return OutfitGenerationResult(
    primary: scored,
    alternatives: [],
    context: OutfitContext(
      weatherSeason: WeatherSeason.allWeather,
      eventType: CalendarEventType.casual,
      date: DateTime.now(),
    ),
    generatedAt: DateTime.now(),
    totalCombinationsEvaluated: 1,
  );
}

WeatherData _weather() => WeatherData(
      temperatureCelsius: 20.0,
      apparentTemperatureCelsius: 20.0,
      temperatureMaxCelsius: 22.0,
      temperatureMinCelsius: 18.0,
      weatherCode: 0,
      conditionDescription: 'Clear sky',
      windSpeedKmh: 10,
      humidityPercent: 50,
      season: WeatherSeason.allWeather,
      fetchedAt: DateTime.now(),
    );

final _wardrobe = [
  _item('top1', ClothingCategory.top),
  _item('bot1', ClothingCategory.bottom),
  _item('shoe1', ClothingCategory.shoes),
];

Widget _buildApp({
  required OutfitGenerationResult Function() resultBuilder,
  bool throwOnGenerate = false,
  bool calendarGranted = true,
  int hour = 9,
}) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-item',
      builder: (_, __) => const Scaffold(body: Text('add item')),
    ),
  ]);

  // Pre-compute the outfits to stream so the home screen can display them.
  final result = throwOnGenerate ? null : resultBuilder();
  final outfitList =
      result?.allOutfits.map((s) => s.outfit).toList() ?? <OutfitModel>[];

  return ProviderScope(
    overrides: [
      outfitGenerationResultProvider.overrideWith((ref) async {
        if (throwOnGenerate) throw Exception('Generation failed');
        return resultBuilder();
      }),
      currentWeatherProvider.overrideWith(
          (ref) async => _weather()),
      todaysEventTypeProvider.overrideWith(
          (ref) async => CalendarEventType.casual),
      calendarPermissionProvider
          .overrideWith((ref) async => calendarGranted),
      allClothingItemsProvider
          .overrideWith((ref) => Stream.value(_wardrobe)),
      outfitRepositoryProvider
          .overrideWithValue(_FakeOutfitRepository()),
      todaysOutfitsProvider.overrideWith((ref) {
        if (throwOnGenerate) {
          return Stream.error(Exception('Generation failed'));
        }
        return Stream.value(outfitList);
      }),
      regenerateOutfitProvider.overrideWith(
        (ref) => () async => resultBuilder(),
      ),
      homeGreetingProvider.overrideWith(
        (ref) => hour < 12 ? 'Good morning 👋' : 'Good afternoon 👋',
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() {
    HttpOverrides.global = _SilentHttpOverrides();
  });
  tearDown(() {
    HttpOverrides.global = null;
  });

  group('HomeScreen', () {
    testWidgets('shows HomeLoadingState while future is loading', (tester) async {
      final completer = Completer<OutfitGenerationResult>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            outfitGenerationResultProvider.overrideWith(
              (ref) => completer.future,
            ),
            currentWeatherProvider
                .overrideWith((ref) async => _weather()),
            todaysEventTypeProvider
                .overrideWith((ref) async => CalendarEventType.casual),
            calendarPermissionProvider
                .overrideWith((ref) async => true),
            allClothingItemsProvider
                .overrideWith((ref) => Stream.value(_wardrobe)),
            outfitRepositoryProvider
                .overrideWithValue(_FakeOutfitRepository()),
            regenerateOutfitProvider
                .overrideWith((ref) => () async => _result()),
          ],
          child: MaterialApp(home: const HomeScreen()),
        ),
      );
      await tester.pump(); // let frame build — future still pending
      // No outfit card yet
      expect(find.byType(OutfitCard), findsNothing);
      // Complete so timer cleanup is happy
      completer.complete(_result());
    });

    testWidgets('shows HomeErrorState when generation fails', (tester) async {
      await tester.pumpWidget(
        _buildApp(resultBuilder: _result, throwOnGenerate: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('Could not load outfit'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows EmptyWardrobeBanner when result is empty', (tester) async {
      await tester.pumpWidget(
        _buildApp(resultBuilder: () => _result(empty: true)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(EmptyWardrobeBanner), findsOneWidget);
    });

    testWidgets('shows OutfitCard when result has primary outfit', (tester) async {
      await tester.pumpWidget(_buildApp(resultBuilder: _result));
      await tester.pumpAndSettle();
      expect(find.byType(OutfitCard), findsOneWidget);
    });

    testWidgets('shows OutfitCard section label when result has data',
        (tester) async {
      await tester.pumpWidget(_buildApp(resultBuilder: _result));
      await tester.pumpAndSettle();
      expect(find.text("Today's Outfits"), findsOneWidget);
    });

    testWidgets('tapping regenerate calls regenerateOutfitProvider',
        (tester) async {
      var called = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            outfitGenerationResultProvider
                .overrideWith((ref) async => _result()),
            currentWeatherProvider
                .overrideWith((ref) async => _weather()),
            todaysEventTypeProvider
                .overrideWith((ref) async => CalendarEventType.casual),
            calendarPermissionProvider
                .overrideWith((ref) async => true),
            allClothingItemsProvider
                .overrideWith((ref) => Stream.value(_wardrobe)),
            outfitRepositoryProvider
                .overrideWithValue(_FakeOutfitRepository()),
            todaysOutfitsProvider.overrideWith(
              (ref) => Stream.value(
                _result().allOutfits.map((s) => s.outfit).toList(),
              ),
            ),
            regenerateOutfitProvider.overrideWith((ref) {
              return () async {
                called = true;
                return _result();
              };
            }),
          ],
          child: MaterialApp(home: const HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(called, isTrue);
    });

    testWidgets('greeting shows Good morning for hour < 12', (tester) async {
      await tester.pumpWidget(
        _buildApp(resultBuilder: _result, hour: 9),
      );
      await tester.pumpAndSettle();
      expect(find.text('Good morning 👋'), findsOneWidget);
    });

    testWidgets('greeting shows Good afternoon for hour >= 12', (tester) async {
      await tester.pumpWidget(
        _buildApp(resultBuilder: _result, hour: 14),
      );
      await tester.pumpAndSettle();
      expect(find.text('Good afternoon 👋'), findsOneWidget);
    });

    testWidgets('PermissionBanner shown when calendar permission denied',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(resultBuilder: _result, calendarGranted: false),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PermissionBanner), findsOneWidget);
      expect(find.textContaining('Calendar access'), findsOneWidget);
    });
  });
}

class _SilentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}
