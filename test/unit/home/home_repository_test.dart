import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/home_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_repository_impl.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_sources.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

void main() {
  test(
    'fresh home cache emits catalog sections without a network request',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final cache = MemoryHomeCacheStore();
      final calendar = _Calendar();
      final repository = _repository(cache, calendar, () => now);
      await cache.writeSections(
        'home:sections:2026-summer:v1',
        CatalogCacheRecord(
          value: HomeCatalogContent(
            hero: <AnimeSummary>[_anime(1, '甲', score: 9)],
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
    },
  );

  test('stale catalog cache survives a failed background refresh', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final calendar = _Calendar(failure: const OfflineFailure());
    final repository = _repository(cache, calendar, () => now);
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

  test('offline home fails the partition without throwing', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(failure: const OfflineFailure()),
      () => now,
    );

    final snapshots = await _collect(repository.watchHome());
    final last = snapshots.last;

    expect(last.catalog.status, HomeSectionStatus.failed);
    expect(last.catalog.failure, isA<OfflineFailure>());
  });

  test('derives the hero by score and the poster grid by popularity', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      () => now,
      heroLimit: 2,
      sectionLimit: 2,
    );

    final snapshots = await _collect(repository.watchHome());
    final sections = snapshots.last.catalog.value!;

    expect(sections.hero.map((item) => item.id.rawId), <int>[1, 2]);
    expect(sections.trending.map((item) => item.id.rawId), <int>[3, 2]);
  });

  test('a refresh bypasses the fresh cache', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final calendar = _Calendar();
    final repository = _repository(cache, calendar, () => now);
    await cache.writeSections(
      'home:sections:2026-summer:v1',
      CatalogCacheRecord(
        value: _content(),
        fetchedAt: now,
        staleAt: now.add(const Duration(minutes: 45)),
        expiresAt: now.add(const Duration(days: 7)),
      ),
    );

    await _collect(repository.watchHome(forceRefresh: true));

    expect(calendar.calls, 1);
    expect(calendar.lastForceNewGeneration, isTrue);
  });
}

HomeRepositoryImpl _repository(
  HomeCacheStore cache,
  _Calendar calendar,
  DateTime Function() now, {
  int heroLimit = 5,
  int sectionLimit = 20,
}) {
  return HomeRepositoryImpl(
    calendarSource: calendar,
    cache: cache,
    now: now,
    heroLimit: heroLimit,
    sectionLimit: sectionLimit,
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
    trending: <AnimeSummary>[_anime(1, '甲', score: 9)],
  );
}

final class _Calendar implements ScheduleCalendarSource {
  _Calendar({this.failure});

  final AppFailure? failure;
  int calls = 0;
  bool? lastForceNewGeneration;

  @override
  Future<List<ScheduleSourceItem>> fetchCalendar({
    bool forceNewGeneration = false,
  }) async {
    calls += 1;
    lastForceNewGeneration = forceNewGeneration;
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
