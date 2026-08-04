import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/data/anilist_discover_source.dart';
import 'package:mio_ani/src/features/discover/data/bangumi_discover_source.dart';
import 'package:mio_ani/src/features/discover/data/discover_cache_store.dart';
import 'package:mio_ani/src/features/discover/data/discover_repository.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';
import 'package:mio_ani/src/features/discover/domain/discover_state.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final coordinator = ref.watch(requestCoordinatorProvider);
  return DiscoverRepositoryImpl(
    bangumi: BangumiDiscoverSource(dio: dio, coordinator: coordinator),
    anilist: AniListDiscoverSource(dio: dio, coordinator: coordinator),
    cache: MemoryDiscoverCacheStore(),
    now: DateTime.now,
  );
});

final class DiscoverController extends Notifier<DiscoverState> {
  DiscoverController(this._initialQuery);

  final DiscoverQuery _initialQuery;
  Timer? _debounce;
  int _generation = 0;
  AnimeSource? _lockedSource;
  bool _hasRequested = false;

  @override
  DiscoverState build() {
    ref.onDispose(() => _debounce?.cancel());
    final query = _initialQuery.normalized();
    _generation += 1;
    return DiscoverState(query: query, generation: _generation);
  }

  void ensureLoaded() {
    if (_hasRequested) return;
    _hasRequested = true;
    _generation += 1;
    final generation = _generation;
    state = state.copyWith(
      status: DiscoverStatus.loading,
      generation: generation,
    );
    unawaited(_load(state.query, generation: generation));
  }

  void setKeyword(String keyword) {
    setQuery(state.query.copyWith(keyword: keyword));
  }

  void setQuery(DiscoverQuery query, {bool immediate = false}) {
    final normalized = query.normalized();
    _debounce?.cancel();
    _hasRequested = true;
    _generation += 1;
    final generation = _generation;
    _lockedSource = normalized.sourcePreference == state.query.sourcePreference
        ? _lockedSource
        : null;
    state = DiscoverState(
      query: normalized,
      generation: generation,
      status: DiscoverStatus.loading,
    );
    if (immediate) {
      unawaited(_load(normalized, generation: generation));
    } else {
      _debounce = Timer(const Duration(milliseconds: 300), () {
        unawaited(_load(normalized, generation: generation));
      });
    }
  }

  void refresh() {
    _generation += 1;
    final generation = _generation;
    state = state.copyWith(
      status: state.hasContent
          ? DiscoverStatus.refreshing
          : DiscoverStatus.loading,
      generation: generation,
      clearFailure: true,
      clearLoadMoreFailure: true,
      clearRateLimitUntil: true,
    );
    unawaited(_load(state.query, generation: generation, forceRefresh: true));
  }

  void retry() => refresh();

  void loadMore() {
    if (!state.hasMore || state.status == DiscoverStatus.loadingMore) {
      return;
    }
    final rateLimitUntil = state.rateLimitUntil;
    if (rateLimitUntil != null && DateTime.now().isBefore(rateLimitUntil)) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(
      status: DiscoverStatus.loadingMore,
      clearLoadMoreFailure: true,
    );
    unawaited(_loadMore(state.query, generation));
  }

  Future<void> _load(
    DiscoverQuery query, {
    required int generation,
    bool forceRefresh = false,
  }) async {
    try {
      final result = await ref
          .read(discoverRepositoryProvider)
          .fetchPage(
            query,
            page: 1,
            lockedSource: _lockedSource,
            forceRefresh: forceRefresh,
          );
      if (generation != _generation) return;
      _lockedSource ??= result.source;
      final catalog = await ref
          .read(discoverRepositoryProvider)
          .fetchFilterCatalog(query, lockedSource: result.source);
      if (generation != _generation) return;
      state = state.copyWith(
        status: result.items.isEmpty
            ? DiscoverStatus.empty
            : DiscoverStatus.contentFresh,
        items: _dedupe(result.items),
        page: 1,
        hasMore: result.hasMore,
        source: result.source,
        filterCatalog: catalog,
        clearFailure: true,
        clearLoadMoreFailure: true,
        clearRateLimitUntil: true,
        fetchedAt: result.fetchedAt,
      );
    } on RateLimitedFailure catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        status: state.hasContent
            ? DiscoverStatus.contentStale
            : DiscoverStatus.rateLimited,
        failure: error,
        rateLimitUntil: DateTime.now().add(
          error.retryAfter ?? const Duration(seconds: 30),
        ),
      );
    } on AppFailure catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        status: state.hasContent
            ? DiscoverStatus.contentStale
            : DiscoverStatus.firstPageError,
        failure: error,
      );
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(
        status: DiscoverStatus.firstPageError,
        failure: const UnknownFailure(),
      );
    }
  }

  Future<void> _loadMore(DiscoverQuery query, int generation) async {
    try {
      final result = await ref
          .read(discoverRepositoryProvider)
          .fetchPage(query, page: state.page + 1, lockedSource: _lockedSource);
      if (generation != _generation) return;
      final merged = _dedupe(<AnimeSummary>[...state.items, ...result.items]);
      state = state.copyWith(
        status: result.hasMore
            ? DiscoverStatus.contentFresh
            : DiscoverStatus.contentFresh,
        items: merged,
        page: result.page,
        hasMore: result.hasMore,
        clearLoadMoreFailure: true,
        fetchedAt: result.fetchedAt,
      );
    } on RateLimitedFailure catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        status: DiscoverStatus.loadMoreError,
        loadMoreFailure: error,
        rateLimitUntil: DateTime.now().add(
          error.retryAfter ?? const Duration(seconds: 30),
        ),
      );
    } on AppFailure catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        status: DiscoverStatus.loadMoreError,
        loadMoreFailure: error,
      );
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(
        status: DiscoverStatus.loadMoreError,
        loadMoreFailure: const UnknownFailure(),
      );
    }
  }

  static List<AnimeSummary> _dedupe(List<AnimeSummary> values) {
    final result = <AnimeSourceId, AnimeSummary>{};
    for (final value in values) {
      result.putIfAbsent(value.id, () => value);
    }
    return result.values.toList(growable: false);
  }
}

final discoverControllerProvider = NotifierProvider.autoDispose
    .family<DiscoverController, DiscoverState, DiscoverQuery>(
      DiscoverController.new,
    );
