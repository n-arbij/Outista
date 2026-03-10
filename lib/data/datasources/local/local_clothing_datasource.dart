import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_enums.dart';
import '../../../core/errors/data_exception.dart';
import '../../database/app_database.dart';
import '../../models/clothing_item_model.dart';
import '../../models/wear_log_model.dart';
import '../../repositories/clothing_repository.dart';
import 'local_wear_log_datasource.dart';

/// Drift-backed implementation of [ClothingRepository].
///
/// All multi-table writes are wrapped in [AppDatabase.transaction].
/// Every method body catches errors and re-throws as [DataException].
class LocalClothingDatasource implements ClothingRepository {
  final AppDatabase _db;
  final LocalWearLogDatasource _wearLog;

  static const _uuid = Uuid();

  LocalClothingDatasource(this._db, this._wearLog);

  // ─── Primary methods (used by providers & engine) ──────────────────────────

  /// Returns all clothing items ordered newest-first.
  Future<List<ClothingItemModel>> getAllItems() async {
    try {
      final rows = await (_db.select(_db.clothingItems)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getAllItems error: $e');
        return true;
      }());
      throw DataException('Failed to get all clothing items', cause: e);
    }
  }

  /// Returns items whose [ClothingItems.category] matches [category].
  Future<List<ClothingItemModel>> getItemsByCategory(
      ClothingCategory category) async {
    try {
      final rows = await (_db.select(_db.clothingItems)
            ..where((t) => t.category.equals(category.name))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getItemsByCategory error: $e');
        return true;
      }());
      throw DataException(
          'Failed to get items by category ${category.name}', cause: e);
    }
  }

  /// Returns the item with [id], or `null` if it does not exist.
  Future<ClothingItemModel?> getItemById(String id) async {
    try {
      final rows = await (_db.select(_db.clothingItems)
            ..where((t) => t.id.equals(id))
            ..limit(1))
          .get();
      return rows.isEmpty ? null : _rowToModel(rows.first);
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getItemById error: $e');
        return true;
      }());
      throw DataException('Failed to get clothing item $id', cause: e);
    }
  }

  /// Inserts [item] into the database.
  Future<void> addItem(ClothingItemModel item) async {
    try {
      await _db
          .into(_db.clothingItems)
          .insert(_modelToCompanion(item));
    } catch (e) {
      assert(() {
        debugPrint('[Outista] addItem error: $e');
        return true;
      }());
      throw DataException('Failed to add clothing item', cause: e);
    }
  }

  /// Updates all fields of an existing [item] matched by its [id].
  Future<void> updateItem(ClothingItemModel item) async {
    try {
      await (_db.update(_db.clothingItems)
            ..where((t) => t.id.equals(item.id)))
          .write(_modelToCompanion(item));
    } catch (e) {
      assert(() {
        debugPrint('[Outista] updateItem error: $e');
        return true;
      }());
      throw DataException('Failed to update clothing item', cause: e);
    }
  }

  /// Deletes the item with [id] and all associated wear logs atomically.
  Future<void> deleteItem(String id) async {
    try {
      await _db.transaction(() async {
        await (_db.delete(_db.clothingItems)
              ..where((t) => t.id.equals(id)))
            .go();
        await _wearLog.deleteLogsForItem(id);
      });
    } catch (e) {
      assert(() {
        debugPrint('[Outista] deleteItem error: $e');
        return true;
      }());
      if (e is DataException) rethrow;
      throw DataException('Failed to delete clothing item $id', cause: e);
    }
  }

  /// Increments [usageCount], sets [lastWornAt] to now, and records a
  /// [WearLog] — all in a single transaction.
  Future<void> recordWear(String itemId) async {
    try {
      await _db.transaction(() async {
        final current = await getItemById(itemId);
        if (current == null) return;

        await (_db.update(_db.clothingItems)
              ..where((t) => t.id.equals(itemId)))
            .write(ClothingItemsCompanion(
              usageCount: Value(current.usageCount + 1),
              lastWornAt: Value(DateTime.now()),
            ));

        await _wearLog.insertLog(WearLogModel(
          id: _uuid.v4(),
          clothingItemId: itemId,
          wornAt: DateTime.now(),
        ));
      });
    } catch (e) {
      assert(() {
        debugPrint('[Outista] recordWear error: $e');
        return true;
      }());
      if (e is DataException) rethrow;
      throw DataException('Failed to record wear for item $itemId', cause: e);
    }
  }

  /// Emits the full wardrobe list (newest-first) and re-emits on any change.
  Stream<List<ClothingItemModel>> watchAllItems() {
    return (_db.select(_db.clothingItems)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_rowToModel).toList());
  }

  // ─── ClothingRepository interface ──────────────────────────────────────────

  @override
  Future<List<ClothingItemModel>> getAll() => getAllItems();

  @override
  Future<ClothingItemModel?> getById(String id) => getItemById(id);

  /// Upserts [item] — inserts or replaces on primary-key conflict.
  @override
  Future<void> save(ClothingItemModel item) async {
    try {
      await _db
          .into(_db.clothingItems)
          .insertOnConflictUpdate(_modelToCompanion(item));
    } catch (e) {
      assert(() {
        debugPrint('[Outista] save error: $e');
        return true;
      }());
      throw DataException('Failed to save clothing item', cause: e);
    }
  }

  @override
  Future<void> delete(String id) => deleteItem(id);

  @override
  Future<List<ClothingItemModel>> getFiltered({
    String? category,
    String? season,
    String? occasion,
  }) async {
    try {
      final query = _db.select(_db.clothingItems)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

      final filters = [
        if (category != null) (t) => t.category.equals(category),
        if (season != null) (t) => t.season.equals(season),
        if (occasion != null) (t) => t.occasion.equals(occasion),
      ];

      if (filters.isNotEmpty) {
        query.where((t) {
          final conditions = [
            if (category != null) t.category.equals(category),
            if (season != null) t.season.equals(season),
            if (occasion != null) t.occasion.equals(occasion),
          ];
          return conditions.reduce((a, b) => a & b);
        });
      }

      final rows = await query.get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getFiltered error: $e');
        return true;
      }());
      throw DataException('Failed to filter clothing items', cause: e);
    }
  }

  /// Returns all items where [isOnePiece] is `true`, ordered newest first.
  @override
  Future<List<ClothingItemModel>> getOnePieceItems() async {
    try {
      final rows = await (_db.select(_db.clothingItems)
            ..where((t) => t.isOnePiece.equals(true))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getOnePieceItems error: $e');
        return true;
      }());
      throw DataException('Failed to get one-piece items', cause: e);
    }
  }

  /// Returns all items that belong to the coord set [setId].
  @override
  Future<List<ClothingItemModel>> getItemsBySetId(String setId) async {
    try {
      final rows = await (_db.select(_db.clothingItems)
            ..where((t) => t.setId.equals(setId)))
          .get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getItemsBySetId error: $e');
        return true;
      }());
      throw DataException('Failed to get items for set $setId', cause: e);
    }
  }

  /// Returns a map of `setId → items` for every coord set in the wardrobe.
  @override
  Future<Map<String, List<ClothingItemModel>>> getCoordSets() async {
    try {
      final rows = await (_db.select(_db.clothingItems)
            ..where((t) => t.setId.isNotNull()))
          .get();
      final result = <String, List<ClothingItemModel>>{};
      for (final row in rows) {
        final model = _rowToModel(row);
        result.putIfAbsent(model.setId!, () => []).add(model);
      }
      return result;
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getCoordSets error: $e');
        return true;
      }());
      throw DataException('Failed to get coord sets', cause: e);
    }
  }

  /// Links [itemId1] and [itemId2] into a new coord set atomically.
  @override
  Future<void> linkCoordSet(String itemId1, String itemId2) async {
    try {
      final newSetId = _uuid.v4();
      await _db.transaction(() async {
        for (final id in [itemId1, itemId2]) {
          await (_db.update(_db.clothingItems)
                ..where((t) => t.id.equals(id)))
              .write(ClothingItemsCompanion(setId: Value(newSetId)));
        }
      });
    } catch (e) {
      assert(() {
        debugPrint('[Outista] linkCoordSet error: $e');
        return true;
      }());
      throw DataException('Failed to link coord set', cause: e);
    }
  }

  /// Removes the coord-set membership of the item with [itemId].
  @override
  Future<void> unlinkCoordSet(String itemId) async {
    try {
      await (_db.update(_db.clothingItems)
            ..where((t) => t.id.equals(itemId)))
          .write(const ClothingItemsCompanion(setId: Value(null)));
    } catch (e) {
      assert(() {
        debugPrint('[Outista] unlinkCoordSet error: $e');
        return true;
      }());
      throw DataException('Failed to unlink coord set for $itemId', cause: e);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  ClothingItemModel _rowToModel(ClothingItem row) => ClothingItemModel(
        id: row.id,
        imagePath: row.imagePath,
        category: ClothingCategory.values.byName(row.category),
        season: ClothingSeason.values.byName(row.season),
        occasion: ClothingOccasion.values.byName(row.occasion),
        emotionalTag: EmotionalTag.values.byName(row.emotionalTag),
        usageCount: row.usageCount,
        createdAt: row.createdAt,
        lastWornAt: row.lastWornAt,
        subcategory: ClothingSubcategory.values.byName(row.subcategory),
        shoeFormality: row.shoeFormality != null
            ? ShoeFormality.values.byName(row.shoeFormality!)
            : null,
        setId: row.setId,
        isOnePiece: row.isOnePiece,
        replacesTop: row.replacesTop,
        replacesBottom: row.replacesBottom,
      );

  ClothingItemsCompanion _modelToCompanion(ClothingItemModel item) =>
      ClothingItemsCompanion(
        id: Value(item.id),
        imagePath: Value(item.imagePath),
        category: Value(item.category.name),
        season: Value(item.season.name),
        occasion: Value(item.occasion.name),
        emotionalTag: Value(item.emotionalTag.name),
        usageCount: Value(item.usageCount),
        createdAt: Value(item.createdAt),
        lastWornAt: Value(item.lastWornAt),
        subcategory: Value(item.subcategory.name),
        shoeFormality: Value(item.shoeFormality?.name),
        setId: Value(item.setId),
        isOnePiece: Value(item.isOnePiece),
        replacesTop: Value(item.replacesTop),
        replacesBottom: Value(item.replacesBottom),
      );
}
