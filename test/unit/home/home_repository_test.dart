import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/home/data/home_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_repository_impl.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_sources.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

void main() {
  test(
    'fresh home cache emits catalog sections without a network request',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final cache = MemoryHomeCacheStore();
      final calendar = _Calendar();
      final schedule = _ScheduleRepo();
      final repository = _repository(cache, calendar, schedule, () => now);
      await cache.writeSections(
        'home:sections:2026-summer:v1',
        CatalogCacheRecord(
          value: HomeCatalogContent(
            hero: <AnimeSummary>[_anime(1, '甲', score: 9)],
            recommended: <AnimeSummary>[_anime(1, '甲', score: 9)],
            trending: <AnimeSummary>[_anime(1, '甲', score: 9)],
          ),
          fetchedAt: now,
          staleAt: now.add(const Duration(minutes: 45)),
          expiresAt: now.add(const Duration(days: 7)),
        ),
      );

      final snapshots = await _collect(repository.watchHome());

      expect(snapshots.last.catalog.status, HomeSectionStatus.ready);
      expect(snapshots.last.catalog.isStale, isFalse);
      expect(calendar.calls, 0);
      expect(snapshots.last.schedule.status, HomeSectionStatus.ready);
    },
  );

  test('stale catalog cache survives a failed background refresh', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final calendar = _Calendar(failure: const OfflineFailure());
    final repository = _repository(cache, calendar, _ScheduleRepo(), () => now);
    await cache.writeSections(
      'home:sections:2026-summer:v1',
      CatalogCacheRecord(
        value: _content(),
        fetchedAt: now.subtract(const Duration(hours: 1)),
        staleAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.add(const Duration(days: 6)),
      ),
    );

    final snapshots = await _collect(repository.watchHome());

    expect(calendar.calls, 1);
    expect(snapshots.last.catalog.refreshFailure, isA<OfflineFailure>());
    expect(snapshots.last.catalog.isStale, isTrue);
  });

  test('catalog failure does not block the schedule partition', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(failure: const OfflineFailure()),
      _ScheduleRepo(),
      () => now,
    );

    final snapshots = await _collect(repository.watchHome());
    final last = snapshots.last;

    expect(last.catalog.status, HomeSectionStatus.failed);
    expect(last.catalog.failure, isA<OfflineFailure>());
    expect(last.schedule.status, HomeSectionStatus.ready);
    expect(last.schedule.value!.days, hasLength(7));
  });

  test('schedule failure does not block the catalog partition', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      _ScheduleRepo(failure: const UpstreamFailure()),
      () => now,
    );

    final snapshots = await _collect(repository.watchHome());
    final last = snapshots.last;

    expect(last.catalog.status, HomeSectionStatus.ready);
    expect(last.catalog.value!.hero, isNotEmpty);
    expect(last.schedule.status, HomeSectionStatus.failed);
    expect(last.schedule.failure, isA<UpstreamFailure>());
  });

  test(
    'fully offline home still emits a snapshot with failed partitions',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final repository = _repository(
        MemoryHomeCacheStore(),
        _Calendar(failure: const OfflineFailure()),
        _ScheduleRepo(failure: const OfflineFailure()),
        () => now,
      );

      final snapshots = await _collect(repository.watchHome());
      final last = snapshots.last;

      expect(last.catalog.status, HomeSectionStatus.failed);
      expect(last.schedule.status, HomeSectionStatus.failed);
    },
  );

  test(
    'derives hero/recommended by score and trending by popularity',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final repository = _repository(
        MemoryHomeCacheStore(),
        _Calendar(),
        _ScheduleRepo(),
        () => now,
        heroLimit: 2,
        sectionLimit: 3,
      );

      final snapshots = await _collect(repository.watchHome());
      final sections = snapshots.last.catalog.value!;

      expect(sections.hero.map((item) => item.id.rawId), <int>[1, 2]);
      expect(sections.recommended.map((item) => item.id.rawId), <int>[1, 2, 3]);
      expect(sections.trending.first.id.rawId, 3);
    },
  );

  test('recent rail and preview come from the schedule week', () async {
    final now = DateTime(2026, 8, 4, 12);
    final schedule = _ScheduleRepo();
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      schedule,
      () => now,
    );

    final snapshots = await _collect(repository.watchHome());
    final content = snapshots.last.schedule.value!;

    expect(content.days, hasLength(7));
    expect(content.recent, isNotEmpty);
    expect(schedule.lastLocalDate, DateTime(2026, 8, 4));
  });
}

HomeRepositoryImpl _repository(
  HomeCacheStore cache,
  _Calendar calendar,
  _ScheduleRepo schedule,
  DateTime Function() now, {
  int heroLimit = 5,
  int sectionLimit = 20,
}) {
  return HomeRepositoryImpl(
    calendarSource: calendar,
    scheduleRepository: schedule,
    cache: cache,
    now: now,
    heroLimit: heroLimit,
    sectionLimit: sectionLimit,
    recentLimit: 10,
  );
}

Future<List<HomeSnapshot>> _collect(Stream<HomeSnapshot> stream) {
  return stream.toList();
}

AnimeSummary _anime(int id, String title, {double? score, int? popularity}) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: '',
    score: score,
    popularity: popularity,
  );
}

HomeCatalogContent _content() {
  return HomeCatalogContent(
    hero: <AnimeSummary>[_anime(1, '甲', score: 9)],
    recommended: <AnimeSummary>[_anime(1, '甲', score: 9)],
    trending: <AnimeSummary>[_anime(1, '甲', score: 9)],
  );
}

final class _Calendar implements ScheduleCalendarSource {
  _Calendar({this.failure});

  final AppFailure? failure;
  int calls = 0;

  @override
  Future<List<ScheduleSourceItem>> fetchCalendar({
    bool forceNewGeneration = false,
  }) async {
    calls += 1;
    final error = failure;
    if (error != null) throw error;
    return <ScheduleSourceItem>[
      ScheduleSourceItem(
        anime: _anime(1, '高分动画', score: 9.0, popularity: 10),
        weekday: ScheduleWeekday.monday,
      ),
      ScheduleSourceItem(
        anime: _anime(2, '中等动画', score: 8.0, popularity: 50),
        weekday: ScheduleWeekday.monday,
      ),
      ScheduleSourceItem(
        anime: _anime(3, '热门动画', score: 7.0, popularity: 100),
        weekday: ScheduleWeekday.tuesday,
      ),
    ];
  }
}

final class _ScheduleRepo implements ScheduleRepository {
  _ScheduleRepo({this.failure});

  final AppFailure? failure;
  DateTime? lastLocalDate;

  @override
  Stream<CatalogSnapshot<BroadcastSchedule>> watchWeek({
    required DateTime localDate,
    bool forceRefresh = false,
  }) {
    lastLocalDate = localDate;
    final error = failure;
    if (error != null) {
      return Stream<CatalogSnapshot<BroadcastSchedule>>.error(error);
    }
    return Stream.value(
      CatalogSnapshot<BroadcastSchedule>(
        value: BroadcastSchedule(
          generatedAt: localDate,
          days: buildWeekSchedule(<ScheduleSourceItem>[
            ScheduleSourceItem(
              anime: _anime(1, '高分动画', score: 9.0, popularity: 10),
              weekday: ScheduleWeekday.monday,
            ),
          ], localDate),
        ),
        fetchedAt: localDate,
        isStale: false,
      ),
    );
  }
}
