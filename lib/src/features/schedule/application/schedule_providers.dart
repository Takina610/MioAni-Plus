import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_schedule_source.dart';
import 'package:mio_ani/src/features/schedule/data/bangumi_calendar_source.dart';
import 'package:mio_ani/src/features/schedule/data/drift_schedule_cache_store.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository_impl.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final coordinator = ref.watch(requestCoordinatorProvider);
  return ScheduleRepositoryImpl(
    calendarSource: BangumiCalendarSource(dio: dio, coordinator: coordinator),
    anilistSource: AniListScheduleSource(dio: dio, coordinator: coordinator),
    cache: DriftScheduleCacheStore(
      database: ref.watch(catalogDatabaseProvider),
    ),
    now: DateTime.now,
  );
});

final scheduleRefreshGenerationProvider = StateProvider.autoDispose
    .family<int, DateTime>((ref, date) => 0);

final scheduleWeekStreamProvider = StreamProvider.autoDispose
    .family<CatalogSnapshot<BroadcastSchedule>, DateTime>((ref, date) {
      final normalized = startOfLocalDay(date);
      final generation = ref.watch(
        scheduleRefreshGenerationProvider(normalized),
      );
      return ref
          .watch(scheduleRepositoryProvider)
          .watchWeek(localDate: normalized, forceRefresh: generation > 0);
    });

/// Immutable schedule page state. The date is the normalized route fact;
/// `snapshot` carries freshness/refresh failures from the repository.
final class ScheduleState {
  const ScheduleState({
    required this.localDate,
    this.snapshot,
    this.failure,
    this.initialLoading = false,
  });

  final DateTime localDate;
  final CatalogSnapshot<BroadcastSchedule>? snapshot;
  final AppFailure? failure;
  final bool initialLoading;

  bool get hasContent => snapshot != null;
}

final class ScheduleController extends Notifier<ScheduleState> {
  ScheduleController(this._date);

  final DateTime _date;

  @override
  ScheduleState build() {
    final normalized = startOfLocalDay(_date);
    final async = ref.watch(scheduleWeekStreamProvider(normalized));
    return switch (async) {
      AsyncData(:final value) => ScheduleState(
        localDate: normalized,
        snapshot: value,
      ),
      AsyncError(:final error) => ScheduleState(
        localDate: normalized,
        failure: error is AppFailure ? error : const UnknownFailure(),
      ),
      _ => ScheduleState(localDate: normalized, initialLoading: true),
    };
  }

  void refresh() {
    final notifier = ref.read(
      scheduleRefreshGenerationProvider(startOfLocalDay(_date)).notifier,
    );
    notifier.state += 1;
  }
}

final scheduleControllerProvider = NotifierProvider.autoDispose
    .family<ScheduleController, ScheduleState, DateTime>(
      ScheduleController.new,
    );
