import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';

/// Structured cache boundary for the weekly schedule template. Keys are the
/// repository's responsibility (`schedule:week:<local-week-start>:v1`).
abstract interface class ScheduleCacheStore {
  Future<CatalogCacheRecord<BroadcastSchedule>?> readWeek(String weekKey);

  Future<void> writeWeek(
    String weekKey,
    CatalogCacheRecord<BroadcastSchedule> record,
  );

  Future<void> deleteWeek(String weekKey);
}

final class MemoryScheduleCacheStore implements ScheduleCacheStore {
  MemoryScheduleCacheStore({
    Map<String, CatalogCacheRecord<BroadcastSchedule>>? weeks,
  }) : _weeks = weeks ?? <String, CatalogCacheRecord<BroadcastSchedule>>{};

  final Map<String, CatalogCacheRecord<BroadcastSchedule>> _weeks;

  @override
  Future<void> deleteWeek(String weekKey) async {
    _weeks.remove(weekKey);
  }

  @override
  Future<CatalogCacheRecord<BroadcastSchedule>?> readWeek(
    String weekKey,
  ) async {
    return _weeks[weekKey];
  }

  @override
  Future<void> writeWeek(
    String weekKey,
    CatalogCacheRecord<BroadcastSchedule> record,
  ) async {
    _weeks[weekKey] = record;
  }
}
