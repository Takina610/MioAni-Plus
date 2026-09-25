import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/home/data/anilist_explore_source.dart';
import 'package:mio_ani/src/features/home/data/anilist_seasonal_source.dart';
import 'package:mio_ani/src/features/home/data/bangumi_explore_source.dart';
import 'package:mio_ani/src/features/home/data/drift_home_cache_store.dart';
import 'package:mio_ani/src/features/home/data/home_repository.dart';
import 'package:mio_ani/src/features/home/data/home_repository_impl.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/schedule/data/bangumi_calendar_source.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final coordinator = ref.watch(requestCoordinatorProvider);
  return HomeRepositoryImpl(
    calendarSource: BangumiCalendarSource(dio: dio, coordinator: coordinator),
    seasonalSource: AniListSeasonalSource(dio: dio, coordinator: coordinator),
    exploreSource: BangumiExploreSource(dio: dio, coordinator: coordinator),
    exploreFallback: AniListExploreSource(dio: dio, coordinator: coordinator),
    cache: DriftHomeCacheStore(database: ref.watch(catalogDatabaseProvider)),
    now: DateTime.now,
  );
});

final homeRefreshGenerationProvider = StateProvider<int>((ref) => 0);

final homeStreamProvider = StreamProvider<HomeSnapshot>((ref) {
  final generation = ref.watch(homeRefreshGenerationProvider);
  return ref
      .watch(homeRepositoryProvider)
      .watchHome(forceRefresh: generation > 0);
});

final class HomeController extends Notifier<HomeSnapshot> {
  @override
  HomeSnapshot build() {
    final async = ref.watch(homeStreamProvider);
    return async.value ?? const HomeSnapshot();
  }

  void refresh() {
    ref.read(homeRefreshGenerationProvider.notifier).state += 1;
  }
}

final homeControllerProvider = NotifierProvider<HomeController, HomeSnapshot>(
  HomeController.new,
);

/// The explore feed grows on demand: the first page arrives with the rest of
/// the home page, every later page when the grid's footer comes into view.
final class HomeExploreController extends Notifier<HomeExploreState> {
  int _generation = 0;

  @override
  HomeExploreState build() {
    unawaited(_readHead(_generation));
    return const HomeExploreState();
  }

  /// True while this instance still owns [generation] and is not disposed.
  ///
  /// A page in flight outlives the state it was started for when the page is
  /// left or a refresh moved on; writing state after that would throw.
  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  /// Re-reads the head of the ranking. What is already on screen stays there
  /// while it runs, and a failure leaves it untouched.
  void refresh() {
    _generation += 1;
    unawaited(_readHead(_generation, forceRefresh: true));
  }

  /// Appends the next page of the ranking.
  void loadMore() {
    if (!state.hasMore || state.status == HomeExploreStatus.loadingMore) return;
    final generation = _generation;
    state = HomeExploreState(
      status: HomeExploreStatus.loadingMore,
      items: state.items,
      page: state.page,
      hasMore: state.hasMore,
    );
    unawaited(_append(generation));
  }

  Future<void> _readHead(int generation, {bool forceRefresh = false}) async {
    try {
      final feed = await ref
          .read(homeRepositoryProvider)
          .readExploreFeed(forceRefresh: forceRefresh);
      if (!_isCurrent(generation)) return;
      state = HomeExploreState(
        status: HomeExploreStatus.ready,
        items: feed.items,
        page: feed.page,
        hasMore: feed.hasMore,
      );
    } on AppFailure catch (failure) {
      if (!_isCurrent(generation) || state.hasContent) return;
      state = HomeExploreState(
        status: HomeExploreStatus.failed,
        failure: failure,
      );
    } on Object {
      if (!_isCurrent(generation) || state.hasContent) return;
      state = const HomeExploreState(
        status: HomeExploreStatus.failed,
        failure: UnknownFailure(),
      );
    }
  }

  Future<void> _append(int generation) async {
    final page = state.page + 1;
    try {
      final feed = await ref.read(homeRepositoryProvider).loadExplorePage(page);
      if (!_isCurrent(generation)) return;
      state = HomeExploreState(
        status: HomeExploreStatus.ready,
        items: feed.items,
        page: feed.page,
        hasMore: feed.hasMore,
      );
    } on AppFailure catch (failure) {
      if (!_isCurrent(generation)) return;
      state = HomeExploreState(
        status: HomeExploreStatus.ready,
        items: state.items,
        page: state.page,
        hasMore: state.hasMore,
        loadMoreFailure: failure,
      );
    } on Object {
      if (!_isCurrent(generation)) return;
      state = HomeExploreState(
        status: HomeExploreStatus.ready,
        items: state.items,
        page: state.page,
        hasMore: state.hasMore,
        loadMoreFailure: const UnknownFailure(),
      );
    }
  }
}

final homeExploreControllerProvider =
    NotifierProvider.autoDispose<HomeExploreController, HomeExploreState>(
      HomeExploreController.new,
    );
