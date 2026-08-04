import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_providers.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';

void main() {
  test(
    'controller starts loading then surfaces the schedule snapshot',
    () async {
      final repository = FakeScheduleRepository();
      final container = ProviderContainer(
        overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final date = DateTime(2026, 8, 4);
      final states = <ScheduleState>[];
      container.listen(
        scheduleControllerProvider(date),
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      expect(states.first.initialLoading, isTrue);

      await container.read(scheduleWeekStreamProvider(date).future);
      await pumpEventQueue();

      final state = states.last;
      expect(state.initialLoading, isFalse);
      expect(state.localDate, DateTime(2026, 8, 4));
      expect(state.hasContent, isTrue);
      expect(state.snapshot!.value.days, hasLength(7));
      expect(repository.lastLocalDate, DateTime(2026, 8, 4));
    },
  );

  test('refresh forces a new repository generation', () async {
    final repository = FakeScheduleRepository();
    final container = ProviderContainer(
      overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final date = DateTime(2026, 8, 4);
    container.listen(
      scheduleControllerProvider(date),
      (_, _) {},
      fireImmediately: true,
    );
    await container.read(scheduleWeekStreamProvider(date).future);
    await pumpEventQueue();
    expect(repository.calls, 1);
    expect(repository.lastForceRefresh, isFalse);

    container.read(scheduleControllerProvider(date).notifier).refresh();
    await container.read(scheduleWeekStreamProvider(date).future);
    await pumpEventQueue();

    expect(repository.calls, 2);
    expect(repository.lastForceRefresh, isTrue);
  });

  test('changing the date creates an independent controller state', () async {
    final repository = FakeScheduleRepository();
    final container = ProviderContainer(
      overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container.listen(
      scheduleControllerProvider(DateTime(2026, 8, 4)),
      (_, _) {},
      fireImmediately: true,
    );
    container.listen(
      scheduleControllerProvider(DateTime(2026, 8, 10)),
      (_, _) {},
      fireImmediately: true,
    );
    await container.read(
      scheduleWeekStreamProvider(DateTime(2026, 8, 4)).future,
    );
    await container.read(
      scheduleWeekStreamProvider(DateTime(2026, 8, 10)).future,
    );
    await pumpEventQueue();

    expect(
      container
          .read(scheduleControllerProvider(DateTime(2026, 8, 4)))
          .localDate,
      DateTime(2026, 8, 4),
    );
    expect(
      container
          .read(scheduleControllerProvider(DateTime(2026, 8, 10)))
          .localDate,
      DateTime(2026, 8, 10),
    );
    expect(repository.lastLocalDate, DateTime(2026, 8, 10));
  });
}

final class FakeScheduleRepository implements ScheduleRepository {
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
    return Stream.value(
      CatalogSnapshot<BroadcastSchedule>(
        value: BroadcastSchedule(
          generatedAt: localDate,
          days: buildWeekSchedule(const <ScheduleSourceItem>[], localDate),
        ),
        fetchedAt: localDate,
        isStale: false,
      ),
    );
  }
}
