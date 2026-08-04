import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_cache_codec.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_cache_store.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';

final class DriftScheduleCacheStore implements ScheduleCacheStore {
  const DriftScheduleCacheStore({
    required this.database,
    this.codec = const ScheduleCacheCodec(),
  });

  final MioAniDatabase database;
  final ScheduleCacheCodec codec;

  @override
  Future<void> deleteWeek(String weekKey) {
    return database.deleteCacheEntry(weekKey);
  }

  @override
  Future<CatalogCacheRecord<BroadcastSchedule>?> readWeek(
    String weekKey,
  ) async {
    final row = await database.readCacheEntry(weekKey);
    if (row == null) return null;
    try {
      return _record(row, codec.decodeWeek(row.payload));
    } on FormatException {
      await deleteWeek(weekKey);
      return null;
    }
  }

  @override
  Future<void> writeWeek(
    String weekKey,
    CatalogCacheRecord<BroadcastSchedule> record,
  ) {
    final payload = codec.encodeWeek(record.value);
    return database.writeCacheEntry(
      StructuredCacheEntriesCompanion.insert(
        cacheKey: weekKey,
        payload: payload,
        fetchedAt: record.fetchedAt.millisecondsSinceEpoch,
        staleAt: record.staleAt.millisecondsSinceEpoch,
        expiresAt: record.expiresAt.millisecondsSinceEpoch,
        category: const Value('schedule'),
        byteSize: Value(utf8.encode(payload).length),
        lastAccessedAt: Value(record.fetchedAt.millisecondsSinceEpoch),
      ),
    );
  }

  CatalogCacheRecord<T> _record<T>(StructuredCacheEntry row, T value) {
    return CatalogCacheRecord<T>(
      value: value,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        row.fetchedAt,
        isUtc: true,
      ),
      staleAt: DateTime.fromMillisecondsSinceEpoch(row.staleAt, isUtc: true),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        row.expiresAt,
        isUtc: true,
      ),
    );
  }
}
