import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_cache_store.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository_impl.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_sources.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_merger.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

void main() {
  test('fresh cache is emitted without a network request', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryScheduleCacheStore();
    final calendar = _Calendar();
    final anilist = _AniList();
    final repository = _repository(cache, calendar, anilist, () => now);
    final schedule = _schedule(now);
    await cache.writeWeek(
      'schedule:week:2026-08-03:v1',
      CatalogCacheRecord(
        value: schedule,
        fetchedAt: now,
        staleAt: now.add(const Duration(hours: 6)),
        expiresAt: now.add(const Duration(days: 7)),
      ),
    );

    final snapshots = await _collect(
      repository.watchWeek(localDate: DateTime(2026, 8, 4)),
    );

    expect(snapshots, hasLength(1));
    expect(snapshots.single.isStale, isFalse);
    expect(snapshots.single.value.days, hasLength(7));
    expect(calendar.calls, 0);
    expect(anilist.calls, 0);
  });

  test('stale cache survives a failed background refresh', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryScheduleCacheStore();
    final calendar = _Calendar(failure: const OfflineFailure());
    final repository = _repository(cache, calendar, _AniList(), () => now);
    await _seed(cache, now, fetchedAt: now.subtract(const Duration(hours: 8)));

    final snapshots = await _collect(
      repository.watchWeek(localDate: DateTime(2026, 8, 4)),
    );

    expect(snapshots, hasLength(2));
    expect(snapshots.first.isStale, isTrue);
    expect(snapshots.last.refreshFailure, isA<OfflineFailure>());
    expect(snapshots.last.isStale, isTrue);
    expect(calendar.calls, 1);
  });

  test('stale cache is followed by a fresh network snapshot', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryScheduleCacheStore();
    final calendar = _Calendar();
    final repository = _repository(cache, calendar, _AniList(), () => now);
    await _seed(cache, now, fetchedAt: now.subtract(const Duration(hours: 8)));

    final snapshots = await _collect(
      repository.watchWeek(localDate: DateTime(2026, 8, 4)),
    );

    expect(snapshots, hasLength(2));
    expect(snapshots.first.isStale, isTrue);
    expect(snapshots.last.isStale, isFalse);
    expect(calendar.calls, 1);
  });

  test('without usable cache preserves platform failures', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryScheduleCacheStore(),
      _Calendar(failure: const OfflineFailure()),
      _AniList(),
      () => now,
    );

    await expectLater(
      _collect(repository.watchWeek(localDate: DateTime(2026, 8, 4))),
      throwsA(isA<OfflineFailure>()),
    );
  });

  test(
    'crossing a local date triggers a background check on fresh cache',
    () async {
      final now = DateTime(2026, 8, 4, 2);
      final cache = MemoryScheduleCacheStore();
      final calendar = _Calendar();
      final anilist = _AniList();
      final repository = _repository(cache, calendar, anilist, () => now);
      await _seed(cache, now, fetchedAt: DateTime(2026, 8, 3, 23), fresh: true);

      final snapshots = await _collect(
        repository.watchWeek(localDate: DateTime(2026, 8, 4)),
      );

      expect(snapshots, hasLength(2));
      expect(snapshots.first.isStale, isTrue);
      expect(snapshots.first.fetchedAt, DateTime(2026, 8, 3, 23));
      expect(snapshots.last.isStale, isFalse);
      expect(calendar.calls, 1);
    },
  );

  test('AniList failure keeps the Bangumi baseline', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryScheduleCacheStore(),
      _Calendar(),
      _AniList(failure: const UpstreamFailure()),
      () => now,
    );

    final snapshots = await _collect(
      repository.watchWeek(localDate: DateTime(2026, 8, 4)),
    );

    expect(snapshots.single.isStale, isFalse);
    expect(snapshots.single.value.days.first.items, hasLength(1));
    expect(snapshots.single.value.days.first.items.single.timed, isFalse);
  });

  test('AniList becomes a fallback when Bangumi fails', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryScheduleCacheStore(),
      _Calendar(failure: const UpstreamFailure()),
      _AniList(
        entries: <AniListAiringEntry>[
          AniListAiringEntry(
            anime: AnimeSummary(
              id: AnimeSourceId.fromAniListId(1),
              title: 'AniList 动画',
              sourceTitle: '',
            ),
            airingAt: DateTime(2026, 8, 4, 22, 30),
          ),
        ],
      ),
      () => now,
    );

    final snapshots = await _collect(
      repository.watchWeek(localDate: DateTime(2026, 8, 4)),
    );

    expect(snapshots.single.isStale, isFalse);
    final tuesday = snapshots.single.value.days.firstWhere(
      (day) => day.weekday == ScheduleWeekday.tuesday,
    );
    expect(tuesday.items, hasLength(1));
    expect(tuesday.items.single.timed, isTrue);
    expect(tuesday.items.single.airTime, ScheduleTime.fromHourMinute(22, 30));
  });

  test('AniList fills missing times and keeps known times', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryScheduleCacheStore(),
      _Calendar(),
      _AniList(
        entries: <AniListAiringEntry>[
          AniListAiringEntry(
            anime: AnimeSummary(
              id: AnimeSourceId.fromAniListId(7),
              title: '动画7',
              sourceTitle: '',
            ),
            airingAt: DateTime(2026, 8, 4, 22, 30),
          ),
        ],
      ),
      () => now,
    );

    final snapshots = await _collect(
      repository.watchWeek(localDate: DateTime(2026, 8, 4)),
    );
    final days = snapshots.single.value.days;
    final tuesday = days.firstWhere(
      (day) => day.weekday == ScheduleWeekday.tuesday,
    );
    final item = tuesday.items.singleWhere((item) => item.anime.id.rawId == 7);
    expect(item.timed, isTrue);
    expect(item.airTime, ScheduleTime.fromHourMinute(22, 30));
  });
}

Future<void> _seed(
  MemoryScheduleCacheStore cache,
  DateTime now, {
  required DateTime fetchedAt,
  bool fresh = false,
}) async {
  final staleAt = fresh
      ? fetchedAt.add(const Duration(hours: 6))
      : fetchedAt.add(const Duration(hours: 1));
  await cache.writeWeek(
    'schedule:week:2026-08-03:v1',
    CatalogCacheRecord(
      value: _schedule(now),
      fetchedAt: fetchedAt,
      staleAt: staleAt,
      expiresAt: fetchedAt.add(const Duration(days: 7)),
    ),
  );
}

ScheduleRepositoryImpl _repository(
  ScheduleCacheStore cache,
  _Calendar calendar,
  _AniList anilist,
  DateTime Function() now,
) {
  return ScheduleRepositoryImpl(
    calendarSource: calendar,
    anilistSource: anilist,
    cache: cache,
    now: now,
    anilistEnrichmentTimeout: const Duration(seconds: 2),
  );
}

Future<List<CatalogSnapshot<BroadcastSchedule>>> _collect(
  Stream<CatalogSnapshot<BroadcastSchedule>> stream,
) {
  return stream.toList();
}

BroadcastSchedule _schedule(DateTime now) {
  return BroadcastSchedule(
    generatedAt: now,
    days: buildWeekSchedule(<ScheduleSourceItem>[
      ScheduleSourceItem(
        anime: AnimeSummary(
          id: AnimeSourceId.fromBangumiId(7),
          title: '动画7',
          sourceTitle: '',
        ),
        weekday: ScheduleWeekday.monday,
      ),
    ], now),
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
        anime: AnimeSummary(
          id: AnimeSourceId.fromBangumiId(7),
          title: '动画7',
          sourceTitle: '',
        ),
        weekday: ScheduleWeekday.monday,
      ),
    ];
  }
}

final class _AniList implements AniListAiringSource {
  _AniList({this.failure, this.entries = const <AniListAiringEntry>[]});

  final AppFailure? failure;
  final List<AniListAiringEntry> entries;
  int calls = 0;

  @override
  Future<List<AniListAiringEntry>> fetchAiringEntries({
    bool forceNewGeneration = false,
  }) async {
    calls += 1;
    final error = failure;
    if (error != null) throw error;
    return entries;
  }
}
