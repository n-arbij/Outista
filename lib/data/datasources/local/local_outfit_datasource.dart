import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/errors/data_exception.dart';
import '../../database/app_database.dart';
import '../../models/outfit_model.dart';
import '../../models/wear_log_model.dart';
import '../../repositories/outfit_repository.dart';
import 'local_clothing_datasource.dart';
import 'local_wear_log_datasource.dart';

/// Drift-backed implementation of [OutfitRepository].
///
/// Requires a [LocalClothingDatasource] (not the abstract interface) so
/// it can call [LocalClothingDatasource.recordWear], which is not part
/// of the abstract [ClothingRepository] contract.
class LocalOutfitDatasource implements OutfitRepository {
  final AppDatabase _db;
  final LocalClothingDatasource _clothing;
  final LocalWearLogDatasource _wearLog;

  static const _uuid = Uuid();

  LocalOutfitDatasource(this._db, this._clothing, this._wearLog);

  // ─── Primary methods ───────────────────────────────────────────────────────

  /// Persists [outfit] to the database.
  ///
  /// If [outfit.wasWorn] is already `true`, also records wear for each
  /// referenced clothing item.
  Future<void> saveOutfit(OutfitModel outfit) async {
    try {
      await _db.into(_db.outfits).insert(_modelToCompanion(outfit));
      if (outfit.wasWorn) {
        for (final itemId in _itemIdsOf(outfit)) {
          await _clothing.recordWear(itemId);
        }
      }
    } catch (e) {
      assert(() {
        debugPrint('[Outista] saveOutfit error: $e');
        return true;
      }());
      if (e is DataException) rethrow;
      throw DataException('Failed to save outfit', cause: e);
    }
  }

  /// Returns the highest-scoring outfit generated today, or `null` if none.
  Future<OutfitModel?> getTodaysOutfit() async {
    try {
      final rows = await _todaysQuery().get();
      return rows.isEmpty ? null : _rowToModel(rows.first);
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getTodaysOutfit error: $e');
        return true;
      }());
      throw DataException("Failed to get today's outfit", cause: e);
    }
  }

  /// Returns all outfits generated today, ordered by score descending.
  Future<List<OutfitModel>> getTodaysOutfits() async {
    try {
      final rows = await _todaysQuery().get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getTodaysOutfits error: $e');
        return true;
      }());
      throw DataException("Failed to get today's outfits", cause: e);
    }
  }

  /// Saves [outfits] in a single transaction, skipping any whose item
  /// combination (topId, bottomId, shoesId, outerwearId) already exists
  /// for today to prevent duplicates.
  ///
  /// Set [isUserAdded] to `true` when saving user-requested outfits (via "+");
  /// `false` (default) marks them as machine-generated and protects them from deletion.
  Future<void> saveAll(List<OutfitModel> outfits,
      {bool isUserAdded = false}) async {
    if (outfits.isEmpty) return;
    try {
      final existing = await getTodaysOutfits();
      final existingCombos = {
        for (final o in existing)
          (o.topId, o.bottomId, o.shoesId, o.outerwearId),
      };

      await _db.transaction(() async {
        for (final outfit in outfits) {
          final combo = (
            outfit.topId,
            outfit.bottomId,
            outfit.shoesId,
            outfit.outerwearId,
          );
          if (existingCombos.contains(combo)) continue;
          existingCombos.add(combo);
          final tagged = OutfitModel(
            id: outfit.id,
            topId: outfit.topId,
            bottomId: outfit.bottomId,
            shoesId: outfit.shoesId,
            outerwearId: outfit.outerwearId,
            score: outfit.score,
            occasionContext: outfit.occasionContext,
            weatherContext: outfit.weatherContext,
            generatedAt: outfit.generatedAt,
            wasWorn: outfit.wasWorn,
            isUserAdded: isUserAdded,
          );
          await _db.into(_db.outfits).insert(_modelToCompanion(tagged));
          if (outfit.wasWorn) {
            for (final itemId in _itemIdsOf(outfit)) {
              await _clothing.recordWear(itemId);
            }
          }
        }
      });
    } catch (e) {
      assert(() {
        debugPrint('[Outista] saveAll error: $e');
        return true;
      }());
      if (e is DataException) rethrow;
      throw DataException('Failed to save outfits', cause: e);
    }
  }

  /// Sets [wasWorn] to `true` on the outfit, calls [recordWear] for each
  /// item (updates usage count / lastWornAt + inserts an item-level
  /// [WearLog]), and also inserts outfit-linked [WearLog] rows.
  Future<void> markOutfitAsWorn(String outfitId) async {
    try {
      await _db.transaction(() async {
        // 1. Mark the outfit row.
        await (_db.update(_db.outfits)
              ..where((t) => t.id.equals(outfitId)))
            .write(const OutfitsCompanion(wasWorn: Value(true)));

        // 2. Fetch the outfit to get item IDs.
        final rows = await (_db.select(_db.outfits)
              ..where((t) => t.id.equals(outfitId)))
            .get();
        if (rows.isEmpty) return;
        final outfit = rows.first;
        final itemIds = _outfitRowItemIds(outfit);

        // 3. Update usage count + lastWornAt via clothing datasource.
        for (final itemId in itemIds) {
          await _clothing.recordWear(itemId);
        }

        // 4. Insert outfit-scoped wear logs.
        final now = DateTime.now();
        for (final itemId in itemIds) {
          await _wearLog.insertLog(WearLogModel(
            id: _uuid.v4(),
            clothingItemId: itemId,
            outfitId: outfitId,
            wornAt: now,
          ));
        }
      });
    } catch (e) {
      assert(() {
        debugPrint('[Outista] markOutfitAsWorn error: $e');
        return true;
      }());
      if (e is DataException) rethrow;
      throw DataException('Failed to mark outfit $outfitId as worn', cause: e);
    }
  }

  /// Returns the [limit] most recently generated outfits, newest first.
  Future<List<OutfitModel>> getOutfitHistory({int limit = 30}) async {
    try {
      final rows = await (_db.select(_db.outfits)
            ..orderBy([(t) => OrderingTerm.desc(t.generatedAt)])
            ..limit(limit))
          .get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getOutfitHistory error: $e');
        return true;
      }());
      throw DataException('Failed to get outfit history', cause: e);
    }
  }

  /// Emits today's highest-scoring outfit (or `null`) and re-emits whenever
  /// the outfits table changes.
  Stream<OutfitModel?> watchTodaysOutfit() {
    return _todaysQuery()
        .watch()
        .map((rows) => rows.isEmpty ? null : _rowToModel(rows.first));
  }

  /// Emits all outfits generated today (score DESC) and re-emits on any
  /// change to the outfits table.
  Stream<List<OutfitModel>> watchTodaysOutfits() {
    return _todaysQuery().watch().map((rows) => rows.map(_rowToModel).toList());
  }

  // ─── OutfitRepository interface ────────────────────────────────────────────

  @override
  Future<List<OutfitModel>> getRecent({int limit = 10}) =>
      getOutfitHistory(limit: limit);

  @override
  Future<OutfitModel?> getById(String id) async {
    try {
      final rows = await (_db.select(_db.outfits)
            ..where((t) => t.id.equals(id))
            ..limit(1))
          .get();
      return rows.isEmpty ? null : _rowToModel(rows.first);
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getById error: $e');
        return true;
      }());
      throw DataException('Failed to get outfit $id', cause: e);
    }
  }

  @override
  Future<void> save(OutfitModel outfit) => saveOutfit(outfit);

  @override
  Future<void> markAsWorn(String id) => markOutfitAsWorn(id);

  @override
  Future<void> delete(String id) async {
    try {
      await (_db.delete(_db.outfits)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] delete outfit error: $e');
        return true;
      }());
      throw DataException('Failed to delete outfit $id', cause: e);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Returns a SELECT statement for today's outfits ordered by score DESC.
  SimpleSelectStatement<$OutfitsTable, Outfit> _todaysQuery() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _db.select(_db.outfits)
      ..where((t) =>
          t.generatedAt.isBiggerOrEqualValue(startOfDay) &
          t.generatedAt.isSmallerThanValue(endOfDay))
      ..orderBy([(t) => OrderingTerm.desc(t.score)]);
  }

  OutfitModel _rowToModel(Outfit row) => OutfitModel(
        id: row.id,
        topId: row.topId,
        bottomId: row.bottomId,
        shoesId: row.shoesId,
        outerwearId: row.outerwearId,
        score: row.score,
        occasionContext: row.occasionContext,
        weatherContext: row.weatherContext,
        generatedAt: row.generatedAt,
        wasWorn: row.wasWorn,
        isUserAdded: row.isUserAdded,
      );

  OutfitsCompanion _modelToCompanion(OutfitModel model) =>
      OutfitsCompanion.insert(
        id: model.id,
        topId: model.topId,
        bottomId: model.bottomId,
        shoesId: model.shoesId,
        outerwearId: Value(model.outerwearId),
        score: model.score,
        occasionContext: model.occasionContext,
        weatherContext: model.weatherContext,
        generatedAt: model.generatedAt,
        wasWorn: Value(model.wasWorn),
        isUserAdded: Value(model.isUserAdded),
      );

  List<String> _itemIdsOf(OutfitModel model) => [
        model.topId,
        model.bottomId,
        model.shoesId,
        if (model.outerwearId != null) model.outerwearId!,
      ];

  List<String> _outfitRowItemIds(Outfit row) => [
        row.topId,
        row.bottomId,
        row.shoesId,
        if (row.outerwearId != null) row.outerwearId!,
      ];
}
