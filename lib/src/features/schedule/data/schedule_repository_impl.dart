import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_cache_store.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_sources.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_merger.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

typedef ScheduleNow = DateTime Function();

final class ScheduleCachePolicy {
  const ScheduleCachePolicy({
    this.freshFor = const Duration(hours: 6),
    this.usableFor = const Duration(days: 7),
  });

  final Duration freshFor;
  final Duration usableFor;

  CatalogCacheRecord<BroadcastSchedule> record(
    BroadcastSchedule value,
    DateTime now,
  ) {
    return CatalogCacheRecord<BroadcastSchedule>(
      value: value,
      fetchedAt: now,
      staleAt: now.add(freshFor),
      expiresAt: now.add(usableFor),
    );
  }
}

final class ScheduleRepositoryImpl implements ScheduleRepository {
  const ScheduleRepositoryImpl({
    required this.calendarSource,
    required this.anilistSource,
    required this.cache,
    required this.now,
    this.policy = const ScheduleCachePolicy(),
    this.anilistEnrichmentTimeout = const Duration(seconds: 8),
  });

  final ScheduleCalendarSource calendarSource;
  final AniListAiringSource anilistSource;
  final ScheduleCacheStore cache;
  final ScheduleNow now;
  final ScheduleCachePolicy policy;
  final Duration anilistEnrichmentTimeout;

  @override
  Stream<CatalogSnapshot<BroadcastSchedule>> watchWeek({
    required DateTime localDate,
    bool forceRefresh = false,
  }) async* {
    final weekStart = mondayOfWeek(localDate);
    final weekKey = 'schedule:week:${localDateKey(weekStart)}:v1';
    final cached = await _readCache(() => cache.readWeek(weekKey));
    final currentTime = now();
    final usableCache =
        cached != null && currentTime.isBefore(cached.expiresAt);
    final freshCache = usableCache && currentTime.isBefore(cached.staleAt);
    final crossDate =
        usableCache &&
        localDateKey(cached.fetchedAt.toLocal()) != localDateKey(currentTime);

    if (usableCache) {
      yield CatalogSnapshot<BroadcastSchedule>(
        value: _withToday(cached.value),
        fetchedAt: cached.fetchedAt,
        isStale: !freshCache || crossDate,
      );
      if (freshCache && !forceRefresh && !crossDate) return;
    }

    try {
      final value = await _fetch(forceNewGeneration: forceRefresh);
      final record = policy.record(value, now());
      await _writeCache(() => cache.writeWeek(weekKey, record));
      yield CatalogSnapshot<BroadcastSchedule>(
        value: value,
        fetchedAt: record.fetchedAt,
        isStale: false,
      );
    } on AppFailure catch (failure) {
      if (!usableCache) rethrow;
      yield CatalogSnapshot<BroadcastSchedule>(
        value: _withToday(cached.value),
        fetchedAt: cached.fetchedAt,
        isStale: true,
        refreshFailure: failure,
      );
    } on Object {
      if (!usableCache) throw const UnknownFailure();
      yield CatalogSnapshot<BroadcastSchedule>(
        value: _withToday(cached.value),
        fetchedAt: cached.fetchedAt,
        isStale: true,
        refreshFailure: const UnknownFailure(),
      );
    }
  }

  Future<BroadcastSchedule> _fetch({required bool forceNewGeneration}) async {
    final currentTime = now();
    List<ScheduleDay> days;
    try {
      final rows = await calendarSource.fetchCalendar(
        forceNewGeneration: forceNewGeneration,
      );
      days = buildWeekSchedule(rows, currentTime);
      final donors = await _anilistBestEffort(forceNewGeneration);
      if (donors.isNotEmpty) {
        days = enrichScheduleWithAiringTimes(days, donors, currentTime);
      }
    } on AppFailure {
      // Bangumi is the primary source; AniList becomes a full fallback only
      // when the calendar itself is unavailable.
      final donors = await _anilistBestEffort(forceNewGeneration);
      if (donors.isEmpty) rethrow;
      days = buildScheduleFromAniList(donors, currentTime);
    }
    return BroadcastSchedule(generatedAt: currentTime, days: days);
  }

  Future<List<AniListAiringEntry>> _anilistBestEffort(
    bool forceNewGeneration,
  ) async {
    try {
      return await anilistSource
          .fetchAiringEntries(forceNewGeneration: forceNewGeneration)
          .timeout(anilistEnrichmentTimeout);
    } on Object {
      return const <AniListAiringEntry>[];
    }
  }

  BroadcastSchedule _withToday(BroadcastSchedule schedule) {
    final today = ScheduleWeekday.fromLocalDate(now());
    return BroadcastSchedule(
      generatedAt: schedule.generatedAt,
      days: <ScheduleDay>[
        for (final day in schedule.days)
          ScheduleDay(
            weekday: day.weekday,
            label: day.label,
            isToday: day.weekday == today,
            items: day.items,
          ),
      ],
    );
  }

  Future<T> _readCache<T>(Future<T> Function() read) async {
    try {
      return await read();
    } on AppFailure {
      rethrow;
    } on Object {
      throw const UnknownFailure();
    }
  }

  Future<void> _writeCache(Future<void> Function() write) async {
    try {
      await write();
    } on AppFailure {
      rethrow;
    } on Object {
      throw const UnknownFailure();
    }
  }
}
