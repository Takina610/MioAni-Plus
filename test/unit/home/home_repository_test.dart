import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/explore_source.dart';
import 'package:mio_ani/src/features/home/data/home_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_repository_impl.dart';
import 'package:mio_ani/src/features/home/data/seasonal_source.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
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
        'home:sections:2026-summer:v2',
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
      'home:sections:2026-summer:v2',
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

  test(
    'derives both sections from the current season by follow count',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final repository = _repository(
        MemoryHomeCacheStore(),
        _Calendar(),
        () => now,
        heroLimit: 2,
        sectionLimit: 3,
      );

      final snapshots = await _collect(repository.watchHome());
      final sections = snapshots.last.catalog.value!;

      // The long-runner is both the best rated and the most followed entry, so
      // it would lead both sections if the season filter were missing; the hero
      // would read [2, 3] if the sections were ordered by score.
      expect(sections.hero.map((item) => item.id.rawId), <int>[3, 2]);
      expect(sections.trending.map((item) => item.id.rawId), <int>[3, 2, 4]);
    },
  );

  test(
    'a season with no calendar entry reads as empty, not as a failure',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final repository = _repository(
        MemoryHomeCacheStore(),
        _Calendar(items: _longRunners),
        () => now,
      );

      final snapshots = await _collect(repository.watchHome());
      final section = snapshots.last.catalog;

      expect(section.status, HomeSectionStatus.ready);
      expect(section.value!.hero, isEmpty);
      expect(section.value!.trending, isEmpty);
    },
  );

  test(
    'an unreachable calendar hands the season to the AniList source',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final seasonal = _Seasonal();
      final repository = _repository(
        MemoryHomeCacheStore(),
        _Calendar(failure: const OfflineFailure()),
        () => now,
        seasonalSource: seasonal,
        heroLimit: 1,
        sectionLimit: 2,
      );

      final snapshots = await _collect(repository.watchHome());
      final sections = snapshots.last.catalog.value!;

      expect(seasonal.calls, 1);
      expect(sections.hero.map((item) => item.id.rawId), <int>[7]);
      expect(sections.trending.map((item) => item.id.rawId), <int>[7, 8]);
    },
  );

  test('a calendar with no entry for the season hands it to AniList', () async {
    final now = DateTime(2026, 8, 4, 12);
    final seasonal = _Seasonal();
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(items: _longRunners),
      () => now,
      seasonalSource: seasonal,
      heroLimit: 1,
      sectionLimit: 1,
    );

    final snapshots = await _collect(repository.watchHome());

    expect(seasonal.calls, 1);
    expect(
      snapshots.last.catalog.value!.hero.map((item) => item.id.rawId),
      <int>[7],
    );
  });

  test(
    'reports the calendar failure when the season fallback fails too',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final repository = _repository(
        MemoryHomeCacheStore(),
        _Calendar(failure: const OfflineFailure()),
        () => now,
        seasonalSource: _Seasonal(failure: const UpstreamFailure()),
      );

      final snapshots = await _collect(repository.watchHome());

      expect(snapshots.last.catalog.failure, isA<OfflineFailure>());
    },
  );

  test('a refresh bypasses the fresh cache', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final calendar = _Calendar();
    final repository = _repository(cache, calendar, () => now);
    await cache.writeSections(
      'home:sections:2026-summer:v2',
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

  test('a warm explore feed answers without a request', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final explore = _Explore(ranking: _ranking());
    final repository = _repository(
      cache,
      _Calendar(),
      () => now,
      explore: explore,
    );
    await _writeExplore(cache, _page(_exploreItems(1), hasMore: true), now);

    final feed = await repository.readExploreFeed();

    expect(explore.calls, 0);
    expect(feed.items.map((item) => item.id.rawId), <int>[100, 101]);
    expect(feed.hasMore, isTrue);
  });

  test(
    'a stale explore feed is refetched from the head of the ranking',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final cache = MemoryHomeCacheStore();
      final explore = _Explore(ranking: _ranking());
      final repository = _repository(
        cache,
        _Calendar(),
        () => now,
        explore: explore,
      );
      await _writeExplore(
        cache,
        _page(_exploreItems(1), hasMore: true),
        now.subtract(const Duration(hours: 2)),
      );

      final feed = await repository.readExploreFeed();

      expect(explore.calls, 1);
      expect(explore.lastPage, 1);
      expect(feed.items, hasLength(2));
    },
  );

  test('a failed explore refresh falls back to the usable cache', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final explore = _Explore(
      ranking: _ranking(),
      failure: const OfflineFailure(),
    );
    final repository = _repository(
      cache,
      _Calendar(),
      () => now,
      explore: explore,
    );
    await _writeExplore(
      cache,
      _page(_exploreItems(1), hasMore: true),
      now.subtract(const Duration(hours: 2)),
    );

    final feed = await repository.readExploreFeed();

    expect(feed.items.map((item) => item.id.rawId), <int>[100, 101]);
  });

  test('a refresh cannot unfinish a feed that reached the end', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      () => now,
      explore: _Explore(ranking: _ranking()),
    );
    final first = await repository.readExploreFeed();
    expect(first.hasMore, isTrue);

    final finished = await repository.loadExplorePage(2);
    expect(finished.hasMore, isFalse);

    // Page 1 keeps reporting pages behind it, but the feed has already walked
    // past them: a refresh must not offer the reader more of a list that ended.
    final refreshed = await repository.readExploreFeed(forceRefresh: true);
    expect(refreshed.items, hasLength(4));
    expect(refreshed.hasMore, isFalse);
  });

  test('an explore refresh keeps the pages already scrolled', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      () => now,
      explore: _Explore(ranking: _ranking(pages: 3)),
    );
    await repository.readExploreFeed();
    await repository.loadExplorePage(2);

    final feed = await repository.readExploreFeed(forceRefresh: true);

    // The head is re-read, and what the reader had already reached stays below
    // it: a refresh must not throw away the pages they scrolled to.
    expect(feed.items, hasLength(4));
    expect(feed.page, 2);
    expect(feed.items.first.title, '探索1-0');
    expect(feed.items.last.title, '探索2-1');
  });

  test('paging appends and drops entries the feed already carries', () async {
    final now = DateTime(2026, 8, 4, 12);
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      () => now,
      explore: _Explore(
        ranking: <List<AnimeSummary>>[
          <AnimeSummary>[_anime(1, '甲'), _anime(2, '乙')],
          // 乙 slid from the first page to the second between two reads.
          <AnimeSummary>[_anime(2, '乙'), _anime(3, '丙')],
        ],
      ),
    );

    await repository.readExploreFeed();
    final feed = await repository.loadExplorePage(2);

    expect(feed.items.map((item) => item.id.rawId), <int>[1, 2, 3]);
    expect(feed.hasMore, isFalse);
  });

  test('the explore feed stops at its limit', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final repository = _repository(
      cache,
      _Calendar(),
      () => now,
      explore: _Explore(ranking: _ranking(pages: 4)),
      exploreLimit: 3,
    );

    expect((await repository.readExploreFeed()).items, hasLength(2));
    expect((await repository.loadExplorePage(2)).items, hasLength(3));

    final third = await repository.loadExplorePage(3);
    expect(third.items, hasLength(3));
    expect(third.hasMore, isFalse);

    // The cached feed carries the cap too: reopening the page cannot grow past
    // it even though the ranking still offers more.
    final reopened = await repository.readExploreFeed(forceRefresh: true);
    expect(reopened.items, hasLength(3));
    expect(reopened.hasMore, isFalse);
  });

  test(
    'a failed explore page travels to the caller and spares the cache',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final cache = MemoryHomeCacheStore();
      final explore = _Explore(ranking: _ranking(pages: 2));
      final repository = _repository(
        cache,
        _Calendar(),
        () => now,
        explore: explore,
      );
      await repository.readExploreFeed();
      explore.pageFailure = const OfflineFailure();

      await expectLater(
        repository.loadExplorePage(2),
        throwsA(isA<OfflineFailure>()),
      );

      final cached = await cache.readExplore(_exploreKey);
      expect(cached!.value.items, hasLength(2));
      expect(cached.value.page, 1);
    },
  );

  test('the preferred ranking answers the explore feed', () async {
    final now = DateTime(2026, 8, 4, 12);
    final preferred = _Explore(ranking: _ranking(), article: 'B-');
    final fallback = _Explore(
      ranking: _ranking(),
      source: AnimeSource.anilist,
      article: 'A-',
    );
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      () => now,
      explore: preferred,
      exploreFallback: fallback,
    );

    final feed = await repository.readExploreFeed();

    expect(feed.source, AnimeSource.bangumi);
    expect(feed.items.first.title, 'B-探索1-0');
    expect(preferred.calls, 1);
    expect(fallback.calls, 0);
  });

  test('the fallback ranking answers when the preferred one cannot', () async {
    final now = DateTime(2026, 8, 4, 12);
    final preferred = _Explore(
      ranking: _ranking(),
      failure: const OfflineFailure(),
      article: 'B-',
    );
    final fallback = _Explore(
      ranking: _ranking(),
      source: AnimeSource.anilist,
      article: 'A-',
    );
    final repository = _repository(
      MemoryHomeCacheStore(),
      _Calendar(),
      () => now,
      explore: preferred,
      exploreFallback: fallback,
    );

    final feed = await repository.readExploreFeed();

    expect(feed.source, AnimeSource.anilist);
    expect(feed.items.first.title, 'A-探索1-0');
    expect(preferred.calls, 1);
    expect(fallback.calls, 1);
  });

  test(
    'a fallback feed returns to the preferred ranking when it answers',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final cache = MemoryHomeCacheStore();
      final preferred = _Explore(ranking: _ranking(), article: 'B-');
      final fallback = _Explore(
        ranking: _ranking(),
        source: AnimeSource.anilist,
        article: 'A-',
      );
      final repository = _repository(
        cache,
        _Calendar(),
        () => now,
        explore: preferred,
        exploreFallback: fallback,
      );
      // What the feed looks like after a spell with Bangumi unreachable.
      await _writeExplore(
        cache,
        _page(<AnimeSummary>[_anime(900, 'A-甲')], source: AnimeSource.anilist),
        now.subtract(const Duration(hours: 2)),
      );

      final feed = await repository.readExploreFeed();

      // The preferred ranking does not merely extend the AniList feed: its list
      // has nothing to do with the order on screen, so the feed restarts from the
      // head of the ranking the app actually wants to read.
      expect(feed.source, AnimeSource.bangumi);
      expect(feed.page, 1);
      expect(feed.items.first.title, 'B-探索1-0');
      expect(preferred.calls, 1);
      expect(fallback.calls, 0);

      // And paging continues in that ranking rather than in the old one.
      await repository.loadExplorePage(2);
      expect(preferred.lastPage, 2);
      expect(fallback.calls, 0);
    },
  );

  test('paging keeps the ranking the feed was read from', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final preferred = _Explore(
      ranking: _ranking(pages: 2),
      failure: const OfflineFailure(),
      article: 'B-',
    );
    final fallback = _Explore(
      ranking: _ranking(pages: 2),
      source: AnimeSource.anilist,
      article: 'A-',
    );
    final repository = _repository(
      cache,
      _Calendar(),
      () => now,
      explore: preferred,
      exploreFallback: fallback,
    );
    await repository.readExploreFeed();

    // Bangumi is still unreachable, but page 2 belongs to the ranking the feed
    // on screen came from: asking Bangumi for it would append a page of a list
    // whose page 1 the reader never saw.
    final feed = await repository.loadExplorePage(2);

    expect(feed.source, AnimeSource.anilist);
    expect(feed.items, hasLength(4));
    expect(feed.items.last.title, 'A-探索2-1');
    expect(fallback.lastPage, 2);
    expect(preferred.calls, 1);
  });

  test(
    'a failed calendar keeps the cached lineup instead of another source',
    () async {
      final now = DateTime(2026, 8, 4, 12);
      final cache = MemoryHomeCacheStore();
      final seasonal = _Seasonal();
      final repository = _repository(
        cache,
        _Calendar(failure: const OfflineFailure()),
        () => now,
        seasonalSource: seasonal,
        heroLimit: 1,
        sectionLimit: 2,
      );
      await cache.writeSections(
        'home:sections:2026-summer:v2',
        CatalogCacheRecord(
          value: HomeCatalogContent(
            hero: <AnimeSummary>[_anime(5, '缓存首推', score: 9)],
            trending: <AnimeSummary>[_anime(5, '缓存首推', score: 9)],
          ),
          fetchedAt: now.subtract(const Duration(hours: 1)),
          staleAt: now.subtract(const Duration(minutes: 15)),
          expiresAt: now.add(const Duration(days: 6)),
        ),
      );

      final snapshots = await _collect(repository.watchHome());
      final section = snapshots.last.catalog;

      // One unreachable request must not swap the reader's Chinese lineup for
      // another source's for the rest of the cache window.
      expect(seasonal.calls, 0);
      expect(section.value!.hero.single.title, '缓存首推');
      expect(section.isStale, isTrue);
      expect(section.refreshFailure, isA<OfflineFailure>());
    },
  );

  test('an empty calendar still hands the season to AniList', () async {
    final now = DateTime(2026, 8, 4, 12);
    final cache = MemoryHomeCacheStore();
    final seasonal = _Seasonal();
    final repository = _repository(
      cache,
      _Calendar(items: _longRunners),
      () => now,
      seasonalSource: seasonal,
      heroLimit: 1,
      sectionLimit: 1,
    );
    await cache.writeSections(
      'home:sections:2026-summer:v2',
      CatalogCacheRecord(
        value: HomeCatalogContent(
          hero: <AnimeSummary>[_anime(5, '缓存首推', score: 9)],
          trending: <AnimeSummary>[_anime(5, '缓存首推', score: 9)],
        ),
        fetchedAt: now.subtract(const Duration(hours: 1)),
        staleAt: now.subtract(const Duration(minutes: 15)),
        expiresAt: now.add(const Duration(days: 6)),
      ),
    );

    final snapshots = await _collect(repository.watchHome());

    // Nothing to serve for the season is a gap the fallback exists to fill, so
    // a cache does not stand in for it the way it does for a failed request.
    expect(seasonal.calls, 1);
    expect(
      snapshots.last.catalog.value!.hero.map((item) => item.id.rawId),
      <int>[7],
    );
  });
}

HomeRepositoryImpl _repository(
  HomeCacheStore cache,
  _Calendar calendar,
  DateTime Function() now, {
  SeasonalAnimeSource? seasonalSource,
  ExploreAnimeSource? explore,
  ExploreAnimeSource? exploreFallback,
  int heroLimit = 5,
  int sectionLimit = 20,
  int exploreLimit = 150,
}) {
  return HomeRepositoryImpl(
    calendarSource: calendar,
    seasonalSource: seasonalSource,
    exploreSource: explore ?? _Explore(),
    exploreFallback: exploreFallback,
    cache: cache,
    now: now,
    heroLimit: heroLimit,
    sectionLimit: sectionLimit,
    exploreLimit: exploreLimit,
  );
}

Future<void> _writeExplore(
  HomeCacheStore cache,
  HomeExplorePage page,
  DateTime fetchedAt,
) {
  return cache.writeExplore(
    _exploreKey,
    CatalogCacheRecord(
      value: page,
      fetchedAt: fetchedAt,
      staleAt: fetchedAt.add(const Duration(minutes: 45)),
      expiresAt: fetchedAt.add(const Duration(days: 7)),
    ),
  );
}

const String _exploreKey = 'home:explore:v2';

HomeExplorePage _page(
  List<AnimeSummary> items, {
  int page = 1,
  bool hasMore = true,
  AnimeSource source = AnimeSource.bangumi,
}) {
  return HomeExplorePage(
    items: items,
    page: page,
    hasMore: hasMore,
    source: source,
  );
}

/// An explore ranking generated page by page, so a test can walk it as deep as
/// the cap allows without writing the posters out by hand.
List<List<AnimeSummary>> _ranking({int pages = 2, int perPage = 2}) {
  return <List<AnimeSummary>>[
    for (var page = 1; page <= pages; page += 1)
      List<AnimeSummary>.generate(
        perPage,
        (index) => _anime(page * 100 + index, '探索$page-$index'),
        growable: false,
      ),
  ];
}

List<AnimeSummary> _exploreItems(int page) => _ranking()[page - 1];

Future<List<HomeSnapshot>> _collect(Stream<HomeSnapshot> stream) {
  return stream.toList();
}

AnimeSummary _anime(
  int id,
  String title, {
  double? score,
  int? popularity,
  DateTime? airDate,
}) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: '',
    score: score,
    popularity: popularity,
    airDate: airDate,
  );
}

/// A show that premiered seasons ago and still holds a weekly calendar slot.
final List<AnimeSummary> _longRunners = <AnimeSummary>[
  _anime(
    1,
    '长跑动画',
    score: 9,
    popularity: 9000,
    airDate: DateTime(1999, 10, 20),
  ),
];

HomeCatalogContent _content() {
  return HomeCatalogContent(
    hero: <AnimeSummary>[_anime(1, '甲', score: 9)],
    trending: <AnimeSummary>[_anime(1, '甲', score: 9)],
  );
}

final class _Calendar implements ScheduleCalendarSource {
  _Calendar({this.failure, List<AnimeSummary>? items})
    : _items = items ?? _defaultItems;

  final AppFailure? failure;
  final List<AnimeSummary> _items;
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
      for (final anime in _items)
        ScheduleSourceItem(anime: anime, weekday: ScheduleWeekday.monday),
    ];
  }
}

/// The AUG 2026 season runs from July 1 to October 1, so the long-runner is the
/// only entry the season filter drops.
final List<AnimeSummary> _defaultItems = <AnimeSummary>[
  ..._longRunners,
  _anime(2, '中等动画', score: 8, popularity: 50, airDate: DateTime(2026, 8, 2)),
  _anime(3, '热门动画', score: 7, popularity: 100, airDate: DateTime(2026, 8, 3)),
  _anime(4, '冷门动画', score: 6, popularity: 10, airDate: DateTime(2026, 8, 4)),
];

final class _Seasonal implements SeasonalAnimeSource {
  _Seasonal({this.failure, List<AnimeSummary>? items})
    : _items = items ?? _fallbackItems;

  final AppFailure? failure;
  final List<AnimeSummary> _items;
  int calls = 0;
  bool? lastForceNewGeneration;

  @override
  Future<List<AnimeSummary>> fetchSeason({
    bool forceNewGeneration = false,
  }) async {
    calls += 1;
    lastForceNewGeneration = forceNewGeneration;
    final error = failure;
    if (error != null) throw error;
    return _items;
  }
}

/// AniList ranks by popularity too, so the fallback list arrives already sorted.
final List<AnimeSummary> _fallbackItems = <AnimeSummary>[
  AnimeSummary(
    id: AnimeSourceId.fromAniListId(7),
    title: 'AniList 热门',
    sourceTitle: '',
    popularity: 900,
  ),
  AnimeSummary(
    id: AnimeSourceId.fromAniListId(8),
    title: 'AniList 次热',
    sourceTitle: '',
    popularity: 800,
  ),
];

/// One page of the source's ranking per entry of [ranking]; nothing sits behind
/// the last page, so the feed ends there.
final class _Explore implements ExploreAnimeSource {
  _Explore({
    List<List<AnimeSummary>>? ranking,
    this.source = AnimeSource.bangumi,
    this.failure,
    this.article,
  }) : ranking = ranking ?? <List<AnimeSummary>>[];

  final List<List<AnimeSummary>> ranking;

  @override
  final AnimeSource source;

  /// Titles are prefixed with this so a test can tell which ranking answered.
  final String? article;

  /// Failure the head of the ranking throws while it is set.
  AppFailure? failure;

  /// Failure every later page throws while it is set.
  AppFailure? pageFailure;

  int calls = 0;
  int? lastPage;
  bool? lastForceNewGeneration;

  @override
  Future<HomeExplorePage> fetchPage(
    int page, {
    bool forceNewGeneration = false,
  }) async {
    calls += 1;
    lastPage = page;
    lastForceNewGeneration = forceNewGeneration;
    final error = page == 1 ? failure : pageFailure;
    if (error != null) throw error;
    final prefix = article;
    return HomeExplorePage(
      items: <AnimeSummary>[
        for (final item
            in page <= ranking.length
                ? ranking[page - 1]
                : const <AnimeSummary>[])
          if (prefix == null)
            item
          else
            AnimeSummary(
              id: item.id,
              title: '$prefix${item.title}',
              sourceTitle: '',
            ),
      ],
      page: page,
      hasMore: page < ranking.length,
      source: source,
    );
  }
}
