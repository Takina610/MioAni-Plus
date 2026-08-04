import 'dart:async';

import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/home_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_repository.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_schedule_source.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_repository.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_sources.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';

typedef HomeNow = DateTime Function();

final class HomeCachePolicy {
  const HomeCachePolicy({
    this.freshFor = const Duration(minutes: 45),
    this.usableFor = const Duration(days: 7),
  });

  final Duration freshFor;
  final Duration usableFor;

  CatalogCacheRecord<HomeCatalogContent> record(
    HomeCatalogContent value,
    DateTime now,
  ) {
    return CatalogCacheRecord<HomeCatalogContent>(
      value: value,
      fetchedAt: now,
      staleAt: now.add(freshFor),
      expiresAt: now.add(usableFor),
    );
  }
}

final class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl({
    required this.calendarSource,
    required this.scheduleRepository,
    required this.cache,
    required this.now,
    this.policy = const HomeCachePolicy(),
    this.heroLimit = 5,
    this.sectionLimit = 20,
    this.recentLimit = 10,
  });

  final ScheduleCalendarSource calendarSource;
  final ScheduleRepository scheduleRepository;
  final HomeCacheStore cache;
  final HomeNow now;
  final HomeCachePolicy policy;
  final int heroLimit;
  final int sectionLimit;
  final int recentLimit;

  @override
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false}) {
    return Stream<HomeSnapshot>.multi((controller) {
      var current = const HomeSnapshot();
      controller.add(current);
      var pendingPartitions = 2;

      void partitionFinished() {
        pendingPartitions -= 1;
        if (pendingPartitions == 0 && !controller.isClosed) {
          controller.close();
        }
      }

      final catalogSub = _catalogPartition(forceRefresh).listen(
        (section) {
          current = current.copyWith(catalog: section);
          if (!controller.isClosed) controller.add(current);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
          partitionFinished();
        },
        onDone: partitionFinished,
      );
      final scheduleSub = _schedulePartition(forceRefresh).listen(
        (section) {
          current = current.copyWith(schedule: section);
          if (!controller.isClosed) controller.add(current);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!controller.isClosed) {
            controller.addError(error, stackTrace);
          }
          partitionFinished();
        },
        onDone: partitionFinished,
      );

      controller.onCancel = () {
        unawaited(catalogSub.cancel());
        unawaited(scheduleSub.cancel());
      };
    });
  }

  Stream<HomeSection<HomeCatalogContent>> _catalogPartition(
    bool forceRefresh,
  ) async* {
    final key = 'home:sections:${_seasonKey(now())}:v1';
    final cached = await _readCache(() => cache.readSections(key));
    final currentTime = now();
    final usableCache =
        cached != null && currentTime.isBefore(cached.expiresAt);
    final freshCache = usableCache && currentTime.isBefore(cached.staleAt);

    if (usableCache) {
      yield HomeSection<HomeCatalogContent>.ready(
        value: cached.value,
        isStale: !freshCache,
        fetchedAt: cached.fetchedAt,
      );
      if (freshCache && !forceRefresh) return;
    }

    try {
      final rows = await calendarSource.fetchCalendar(
        forceNewGeneration: forceRefresh,
      );
      final summaries = <AnimeSummary>[];
      final seen = <String>{};
      for (final row in rows) {
        if (seen.add(row.anime.id.value)) summaries.add(row.anime);
      }
      final sections = _catalogSections(summaries);
      final record = policy.record(sections, now());
      await _writeCache(() => cache.writeSections(key, record));
      yield HomeSection<HomeCatalogContent>.ready(
        value: sections,
        isStale: false,
        fetchedAt: record.fetchedAt,
      );
    } on AppFailure catch (failure) {
      if (!usableCache) {
        yield HomeSection<HomeCatalogContent>.failed(failure);
        return;
      }
      yield HomeSection<HomeCatalogContent>.ready(
        value: cached.value,
        isStale: true,
        fetchedAt: cached.fetchedAt,
        refreshFailure: failure,
      );
    } on Object {
      if (!usableCache) {
        yield const HomeSection<HomeCatalogContent>.failed(UnknownFailure());
        return;
      }
      yield HomeSection<HomeCatalogContent>.ready(
        value: cached.value,
        isStale: true,
        fetchedAt: cached.fetchedAt,
        refreshFailure: const UnknownFailure(),
      );
    }
  }

  Stream<HomeSection<HomeScheduleContent>> _schedulePartition(
    bool forceRefresh,
  ) async* {
    try {
      await for (final snapshot in scheduleRepository.watchWeek(
        localDate: startOfLocalDay(now()),
        forceRefresh: forceRefresh,
      )) {
        yield HomeSection<HomeScheduleContent>.ready(
          value: HomeScheduleContent(
            recent: flattenRecentSchedule(snapshot.value.days, recentLimit),
            days: snapshot.value.days,
          ),
          isStale: snapshot.isStale,
          fetchedAt: snapshot.fetchedAt,
          refreshFailure: snapshot.refreshFailure,
        );
      }
    } on AppFailure catch (failure) {
      yield HomeSection<HomeScheduleContent>.failed(failure);
    } on Object {
      yield const HomeSection<HomeScheduleContent>.failed(UnknownFailure());
    }
  }

  HomeCatalogContent _catalogSections(List<AnimeSummary> summaries) {
    final byScore = <AnimeSummary>[...summaries]
      ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    final byPopularity = <AnimeSummary>[...summaries]
      ..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
    return HomeCatalogContent(
      hero: byScore.take(heroLimit).toList(growable: false),
      recommended: byScore.take(sectionLimit).toList(growable: false),
      trending: byPopularity.take(sectionLimit).toList(growable: false),
    );
  }

  String _seasonKey(DateTime value) {
    final resolved = currentAniListSeason(value);
    return '${resolved.year}-${resolved.season.name}';
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
