import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';

CatalogSnapshot<BroadcastSchedule> testScheduleSnapshot(
  DateTime date, {
  bool isStale = false,
  List<ScheduleSourceItem>? items,
}) {
  return CatalogSnapshot<BroadcastSchedule>(
    value: BroadcastSchedule(
      generatedAt: date,
      days: buildWeekSchedule(items ?? const <ScheduleSourceItem>[], date),
    ),
    fetchedAt: DateTime.utc(2026, 8, 4, 8),
    isStale: isStale,
  );
}

final class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository({
    Stream<CatalogSnapshot<BroadcastSchedule>> Function()? watchFactory,
    this.failure,
  }) : _watchFactory =
           watchFactory ??
           (() => Stream.value(testScheduleSnapshot(DateTime.now())));

  final Stream<CatalogSnapshot<BroadcastSchedule>> Function() _watchFactory;
  final Object? failure;
  int calls = 0;
  bool? lastForceRefresh;
  DateTime? lastLocalDate;

  @override
  Stream<CatalogSnapshot<BroadcastSchedule>> watchWeek({
    required DateTime localDate,
    bool forceRefresh = false,
  }) {
    calls += 1;
    lastForceRefresh = forceRefresh;
    lastLocalDate = localDate;
    final error = failure;
    if (error != null) {
      return Stream<CatalogSnapshot<BroadcastSchedule>>.error(error);
    }
    return _watchFactory();
  }
}
