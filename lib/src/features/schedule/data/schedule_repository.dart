import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';

abstract interface class ScheduleRepository {
  /// Watches the fixed Monday→Sunday week template containing [localDate].
  ///
  /// Emits cached content immediately (marked stale when expired), then a
  /// fresh snapshot after a network round trip. Crossing a local calendar date
  /// triggers a background freshness check even when the cache is fresh.
  Stream<CatalogSnapshot<BroadcastSchedule>> watchWeek({
    required DateTime localDate,
    bool forceRefresh = false,
  });
}
