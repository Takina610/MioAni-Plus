import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/home_repository.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

HomeSnapshot testHomeSnapshot({HomeSection<HomeCatalogContent>? catalog}) {
  return HomeSnapshot(
    catalog:
        catalog ??
        const HomeSection<HomeCatalogContent>.ready(
          value: HomeCatalogContent(
            hero: <AnimeSummary>[],
            trending: <AnimeSummary>[],
          ),
        ),
  );
}

/// An explore ranking of [pages] pages of [perPage] posters, with nothing
/// behind the last one — what a server that has stopped offering more looks
/// like.
///
/// The default page size is a real one: how much of a page fits on screen is
/// what decides how far the feed is read ahead, so a feed of three-poster pages
/// would exercise a shape the app never sees.
List<List<AnimeSummary>> testExploreRanking({int pages = 2, int perPage = 20}) {
  return <List<AnimeSummary>>[
    for (var page = 0; page < pages; page += 1)
      <AnimeSummary>[
        for (var index = 0; index < perPage; index += 1)
          AnimeSummary(
            id: AnimeSourceId.fromAniListId(page * perPage + index + 1),
            title: '探索${page + 1}-${index + 1}',
            sourceTitle: '',
          ),
      ],
  ];
}

final class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({
    Stream<HomeSnapshot> Function()? watchFactory,
    List<List<AnimeSummary>>? explorePages,
    this.exploreSource = AnimeSource.bangumi,
    this.exploreFailure,
    this.explorePageFailure,
  }) : _watchFactory = watchFactory ?? (() => Stream.value(testHomeSnapshot())),
       _explorePages = explorePages ?? const <List<AnimeSummary>>[];

  final Stream<HomeSnapshot> Function() _watchFactory;

  /// The ranking the whole feed comes from, as [FakeHomeRepository] answers it.
  final AnimeSource exploreSource;

  /// One list of posters per page. The fake answers [loadExplorePage] by
  /// accumulating the pages up to the one asked for, the way the repository
  /// hands back the whole feed, and reports an end behind the last page.
  final List<List<AnimeSummary>> _explorePages;

  /// Failure the head of the feed throws while it is set. Mutable, so a test
  /// can fail once and then let a retry through.
  AppFailure? exploreFailure;

  /// Failure every later page throws while it is set.
  AppFailure? explorePageFailure;

  int calls = 0;
  bool? lastForceRefresh;

  /// How many explore requests the fake saw, and how they were addressed.
  int exploreRequests = 0;
  int? lastExplorePage;
  bool? lastExploreForceRefresh;

  /// The deepest page served so far. It is what the repository does with its
  /// cache: the feed handed back is everything known, not the last page alone.
  int _served = 0;

  @override
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false}) {
    calls += 1;
    lastForceRefresh = forceRefresh;
    return _watchFactory();
  }

  @override
  Future<HomeExplorePage> readExploreFeed({bool forceRefresh = false}) async {
    exploreRequests += 1;
    lastExplorePage = 1;
    lastExploreForceRefresh = forceRefresh;
    final failure = exploreFailure;
    if (failure != null) throw failure;
    if (_served == 0) _served = 1;
    return _feed(_served);
  }

  @override
  Future<HomeExplorePage> loadExplorePage(int page) async {
    exploreRequests += 1;
    lastExplorePage = page;
    final failure = explorePageFailure;
    if (failure != null) throw failure;
    if (page > _served) _served = page;
    return _feed(_served);
  }

  HomeExplorePage _feed(int page) {
    final items = <AnimeSummary>[];
    for (
      var index = 0;
      index < page && index < _explorePages.length;
      index += 1
    ) {
      items.addAll(_explorePages[index]);
    }
    return HomeExplorePage(
      items: items,
      page: page,
      hasMore: page < _explorePages.length,
      source: exploreSource,
    );
  }
}
