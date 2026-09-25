import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/explore_source.dart';
import 'package:mio_ani/src/features/home/data/home_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_repository.dart';
import 'package:mio_ani/src/features/home/data/seasonal_source.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/domain/season_window.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_schedule_source.dart';
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

  CatalogCacheRecord<T> record<T>(T value, DateTime now) {
    return CatalogCacheRecord<T>(
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
    required this.exploreSource,
    this.exploreFallback,
    this.seasonalSource,
    required this.cache,
    required this.now,
    this.policy = const HomeCachePolicy(),
    this.heroLimit = 5,
    this.sectionLimit = 20,
    this.exploreLimit = 150,
  });

  final ScheduleCalendarSource calendarSource;

  /// The season lineup to publish when the calendar has nothing for the season
  /// yet or cannot be reached. Both home sections read one season only, so this
  /// source never widens the list to another season.
  final SeasonalAnimeSource? seasonalSource;

  /// The preferred ranking behind the explore feed, which walks as far as
  /// [exploreLimit] and no further.
  ///
  /// This is Bangumi's heat ranking: home content reads in Chinese, and the
  /// preferred source is what keeps the feed there.
  final ExploreAnimeSource exploreSource;

  /// The ranking that stands in when the preferred one cannot answer at all.
  ///
  /// It never interrupts a working feed — a page of another ranking cannot
  /// extend a list whose pages were counted somewhere else — so it is reached
  /// only where the preferred ranking has nothing to say, and a feed it served
  /// returns to the preferred ranking as soon as that one answers again.
  final ExploreAnimeSource? exploreFallback;
  final HomeCacheStore cache;
  final HomeNow now;
  final HomeCachePolicy policy;
  final int heroLimit;
  final int sectionLimit;

  /// How many posters the explore feed may grow to.
  ///
  /// The feed is one lazy grid, so the ceiling is not about the widget tree: it
  /// is what a browsing session is worth. Eight pages of Bangumi's ranking is
  /// several minutes of scrolling, tens of megabytes of posters through the
  /// shared image cache, and past it the feed has left the titles anyone
  /// recognises. A finite feed also ends instead of pretending to be endless.
  final int exploreLimit;

  static const String _exploreKey = 'home:explore:v2';

  @override
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false}) {
    return _catalogPartition(
      forceRefresh,
    ).map((section) => HomeSnapshot(catalog: section));
  }

  Stream<HomeSection<HomeCatalogContent>> _catalogPartition(
    bool forceRefresh,
  ) async* {
    final key = 'home:sections:${_seasonKey(now())}:v2';
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
      final lineup = await _seasonLineup(
        forceRefresh,
        mayFallBack: !usableCache,
      );
      final sections = _catalogSections(lineup);
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

  @override
  Future<HomeExplorePage> readExploreFeed({bool forceRefresh = false}) async {
    final cached = await _readCache(() => cache.readExplore(_exploreKey));
    final current = now();
    if (cached != null && !forceRefresh && current.isBefore(cached.staleAt)) {
      return cached.value;
    }

    final held = cached?.value;
    AppFailure? failure;
    for (final rank in _headRanks(held)) {
      final HomeExplorePage page;
      try {
        page = await rank.fetchPage(1, forceNewGeneration: forceRefresh);
      } on AppFailure catch (error) {
        failure ??= error;
        continue;
      }
      // Stored outside the loop's failure handling: a cache that will not write
      // is not the ranking's fault, and must not send the feed to another one.
      return _storeExplore(_feed(page, previous: held));
    }
    if (held != null && current.isBefore(cached!.expiresAt)) return held;
    throw failure ?? const UnknownFailure();
  }

  @override
  Future<HomeExplorePage> loadExplorePage(int page) async {
    final cached = await _readCache(() => cache.readExplore(_exploreKey));
    final held = cached?.value;
    final rank = _rankFor(held?.source) ?? exploreSource;
    final next = await rank.fetchPage(page);
    return _storeExplore(_feed(next, previous: held));
  }

  /// The rankings a head re-read may ask, in order.
  ///
  /// The preferred ranking answers first: it is the one the rest of the home
  /// page reads from, so a feed that once fell back returns to it as soon as it
  /// is reachable. A feed already on record keeps its own ranking behind it —
  /// re-reading page 1 of a list the reader never saw would be a different
  /// feed, not a refreshed one.
  List<ExploreAnimeSource> _headRanks(HomeExplorePage? held) {
    final ranks = <ExploreAnimeSource>[exploreSource, ?exploreFallback];
    final heldRank = _rankFor(held?.source);
    if (heldRank == null) return ranks;
    return <ExploreAnimeSource>[
      exploreSource,
      if (!identical(heldRank, exploreSource)) heldRank,
    ];
  }

  ExploreAnimeSource? _rankFor(AnimeSource? source) {
    if (source == null) return null;
    for (final rank in <ExploreAnimeSource>[exploreSource, ?exploreFallback]) {
      if (rank.source == source) return rank;
    }
    return null;
  }

  Future<HomeExplorePage> _storeExplore(HomeExplorePage feed) async {
    await _writeCache(
      () => cache.writeExplore(_exploreKey, policy.record(feed, now())),
    );
    return feed;
  }

  /// Folds a freshly fetched page onto the feed already known.
  ///
  /// A deeper page of the same ranking extends the feed; page 1 is what a
  /// refresh re-reads, so it takes the place of the ranking's head and the
  /// pages already scrolled stay behind it. A page of *another* ranking is
  /// neither: its order has nothing to do with the list on screen, so it
  /// restarts the feed from its own head. Entries are deduplicated by identity
  /// — a title that moved between two pages must not appear twice — and the
  /// feed stops at [exploreLimit] whatever the source still offers behind it.
  HomeExplorePage _feed(HomeExplorePage page, {HomeExplorePage? previous}) {
    final held = previous;
    if (held == null || held.items.isEmpty || held.source != page.source) {
      return _feedRecord(
        page.items,
        page: page.page,
        source: page.source,
        sourceHasMore: page.hasMore,
      );
    }
    final readsTheHead = page.page <= held.page;
    return _feedRecord(
      readsTheHead
          ? <AnimeSummary>[...page.items, ...held.items]
          : <AnimeSummary>[...held.items, ...page.items],
      page: readsTheHead ? held.page : page.page,
      source: page.source,
      // Where a ranking ends is known from the *deepest* page read, not from
      // its head: page 1 reports pages behind it even when the feed has already
      // walked to the last one. Re-reading the head therefore cannot unfinish a
      // feed that had reached the end.
      sourceHasMore: readsTheHead ? held.hasMore : page.hasMore,
    );
  }

  HomeExplorePage _feedRecord(
    List<AnimeSummary> ordered, {
    required int page,
    required AnimeSource source,
    required bool sourceHasMore,
  }) {
    final items = <AnimeSummary>[];
    final seen = <AnimeSourceId>{};
    for (final item in ordered) {
      if (items.length == exploreLimit) break;
      if (seen.add(item.id)) items.add(item);
    }
    return HomeExplorePage(
      items: items,
      page: page,
      source: source,
      // The cap is a promise to the device, not to the source: once the feed is
      // full there is nothing left to load even if the ranking continues.
      hasMore: sourceHasMore && items.length < exploreLimit,
    );
  }

  /// The current season's lineup, which both home sections are cut from.
  ///
  /// Bangumi's weekly calendar is the primary source, but it is a template of
  /// everything still airing: a show that premiered seasons ago keeps its slot
  /// every week, so entries are kept only when their premiere falls in the
  /// current season. Around a season change the calendar carries no entry for
  /// the new season yet, and the AniList season ranking stands in rather than
  /// letting the home page fall back to the season that just ended.
  ///
  /// [mayFallBack] is false when a usable cache is already on screen. The
  /// fallback fills a gap where the calendar has nothing to say; it must not
  /// answer *for* the calendar, or one unreachable request would replace a
  /// working Bangumi lineup with another source's for the rest of the cache
  /// window — in another language, and without the reader asking for it.
  Future<List<AnimeSummary>> _seasonLineup(
    bool forceNewGeneration, {
    required bool mayFallBack,
  }) async {
    final seasonNow = now();
    AppFailure? calendarFailure;
    try {
      final rows = await calendarSource.fetchCalendar(
        forceNewGeneration: forceNewGeneration,
      );
      final lineup = _seasonEntries(rows, seasonNow);
      if (lineup.isNotEmpty) return lineup;
    } on AppFailure catch (failure) {
      calendarFailure = failure;
      if (!mayFallBack) rethrow;
    }
    return _seasonFallback(forceNewGeneration, calendarFailure);
  }

  Future<List<AnimeSummary>> _seasonFallback(
    bool forceNewGeneration,
    AppFailure? calendarFailure,
  ) async {
    final source = seasonalSource;
    if (source == null) {
      // Without a fallback the calendar stays the whole answer, and an empty
      // season is a season with nothing to show rather than a failure.
      if (calendarFailure != null) throw calendarFailure;
      return const <AnimeSummary>[];
    }
    try {
      return await source.fetchSeason(forceNewGeneration: forceNewGeneration);
    } on AppFailure {
      // The calendar's own failure is the one the caller already knows how to
      // report against its cache.
      if (calendarFailure != null) throw calendarFailure;
      rethrow;
    }
  }

  List<AnimeSummary> _seasonEntries(
    List<ScheduleSourceItem> rows,
    DateTime seasonNow,
  ) {
    final entries = <AnimeSummary>[];
    final seen = <String>{};
    for (final row in rows) {
      final anime = row.anime;
      if (!isInCurrentSeason(anime.airDate, seasonNow)) continue;
      if (seen.add(anime.id.value)) entries.add(anime);
    }
    return entries;
  }

  /// The hero is the head of the season ranking and the poster grid the rest of
  /// it, so the carousel and the grid never disagree about what is popular.
  HomeCatalogContent _catalogSections(List<AnimeSummary> lineup) {
    final byPopularity = <AnimeSummary>[...lineup]
      ..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
    return HomeCatalogContent(
      hero: byPopularity.take(heroLimit).toList(growable: false),
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
