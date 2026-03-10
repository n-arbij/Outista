import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../../../core/constants/app_constants.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

/// Stores individual clothing items in the user's wardrobe.
class ClothingItems extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();

  /// Serialised [ClothingCategory] enum name.
  TextColumn get category => text()();

  /// Serialised [ClothingSeason] enum name.
  TextColumn get season => text()();

  /// Serialised [ClothingOccasion] enum name.
  TextColumn get occasion => text()();

  /// Serialised [EmotionalTag] enum name; defaults to 'none'.
  TextColumn get emotionalTag =>
      text().withDefault(const Constant('none'))();

  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastWornAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores generated outfit combinations.
class Outfits extends Table {
  TextColumn get id => text()();
  @ReferenceName('topOutfitsRefs')
  TextColumn get topId => text().references(ClothingItems, #id)();
  @ReferenceName('bottomOutfitsRefs')
  TextColumn get bottomId => text().references(ClothingItems, #id)();
  @ReferenceName('shoesOutfitsRefs')
  TextColumn get shoesId => text().references(ClothingItems, #id)();
  @ReferenceName('outerwearOutfitsRefs')
  TextColumn get outerwearId =>
      text().references(ClothingItems, #id).nullable()();
  RealColumn get score => real()();

  /// Serialised [CalendarEventType] enum name.
  TextColumn get occasionContext => text()();

  /// Serialised [WeatherSeason] enum name.
  TextColumn get weatherContext => text()();

  DateTimeColumn get generatedAt => dateTime()();
  BoolColumn get wasWorn => boolean().withDefault(const Constant(false))();

  /// Whether this outfit was explicitly requested by the user via the "+" button.
  /// `false` = machine-generated on app load; protected from deletion.
  BoolColumn get isUserAdded =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Records every time a clothing item or outfit was worn.
class WearLogs extends Table {
  TextColumn get id => text()();
  TextColumn get clothingItemId => text().references(ClothingItems, #id)();
  TextColumn get outfitId => text().references(Outfits, #id).nullable()();
  DateTimeColumn get wornAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [ClothingItems, Outfits, WearLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(outfits, outfits.isUserAdded);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: AppConstants.databaseName);
  }
}
