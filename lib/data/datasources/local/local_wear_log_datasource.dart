import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../../core/errors/data_exception.dart';
import '../../database/app_database.dart';
import '../../models/wear_log_model.dart';

/// Standalone datasource for [WearLog] persistence.
///
/// Has no abstract interface — consumed directly by the clothing and
/// outfit datasources that need to write wear events.
class LocalWearLogDatasource {
  final AppDatabase _db;

  LocalWearLogDatasource(this._db);

  /// Inserts a new [WearLogModel] row.
  Future<void> insertLog(WearLogModel log) async {
    try {
      await _db.into(_db.wearLogs).insert(
            WearLogsCompanion.insert(
              id: log.id,
              clothingItemId: log.clothingItemId,
              outfitId: Value(log.outfitId),
              wornAt: log.wornAt,
            ),
          );
    } catch (e) {
      assert(() {
        debugPrint('[Outista] insertLog error: $e');
        return true;
      }());
      throw DataException('Failed to insert wear log', cause: e);
    }
  }

  /// Returns all wear logs for [itemId], newest first.
  Future<List<WearLogModel>> getLogsForItem(String itemId) async {
    try {
      final rows = await (_db.select(_db.wearLogs)
            ..where((t) => t.clothingItemId.equals(itemId))
            ..orderBy([(t) => OrderingTerm.desc(t.wornAt)]))
          .get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getLogsForItem error: $e');
        return true;
      }());
      throw DataException('Failed to get wear logs for item $itemId',
          cause: e);
    }
  }

  /// Returns all wear logs whose [WearLog.wornAt] falls within [start]..[end].
  Future<List<WearLogModel>> getLogsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final rows = await (_db.select(_db.wearLogs)
            ..where((t) =>
                t.wornAt.isBiggerOrEqualValue(start) &
                t.wornAt.isSmallerOrEqualValue(end)))
          .get();
      return rows.map(_rowToModel).toList();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] getLogsForDateRange error: $e');
        return true;
      }());
      throw DataException('Failed to get wear logs for date range', cause: e);
    }
  }

  /// Deletes all wear logs associated with [itemId].
  Future<void> deleteLogsForItem(String itemId) async {
    try {
      await (_db.delete(_db.wearLogs)
            ..where((t) => t.clothingItemId.equals(itemId)))
          .go();
    } catch (e) {
      assert(() {
        debugPrint('[Outista] deleteLogsForItem error: $e');
        return true;
      }());
      throw DataException('Failed to delete wear logs for item $itemId',
          cause: e);
    }
  }

  WearLogModel _rowToModel(WearLog row) => WearLogModel(
        id: row.id,
        clothingItemId: row.clothingItemId,
        outfitId: row.outfitId,
        wornAt: row.wornAt,
      );
}
