import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

enum DiscoverStatus {
  initial,
  loading,
  contentFresh,
  contentStale,
  refreshing,
  empty,
  offlineEmpty,
  firstPageError,
  loadingMore,
  loadMoreError,
  rateLimited,
}

final class DiscoverState {
  const DiscoverState({
    this.query = const DiscoverQuery(),
    this.status = DiscoverStatus.initial,
    this.items = const <AnimeSummary>[],
    this.page = 0,
    this.hasMore = false,
    this.source,
    this.failure,
    this.loadMoreFailure,
    this.rateLimitUntil,
    this.filterCatalog,
    this.generation = 0,
    this.fetchedAt,
  });

  final DiscoverQuery query;
  final DiscoverStatus status;
  final List<AnimeSummary> items;
  final int page;
  final bool hasMore;
  final AnimeSource? source;
  final AppFailure? failure;
  final AppFailure? loadMoreFailure;
  final DateTime? rateLimitUntil;
  final DiscoverFilterCatalog? filterCatalog;
  final int generation;
  final DateTime? fetchedAt;

  bool get isLoading =>
      status == DiscoverStatus.loading || status == DiscoverStatus.refreshing;
  bool get hasContent => items.isNotEmpty;

  DiscoverState copyWith({
    DiscoverQuery? query,
    DiscoverStatus? status,
    List<AnimeSummary>? items,
    int? page,
    bool? hasMore,
    AnimeSource? source,
    bool clearSource = false,
    AppFailure? failure,
    bool clearFailure = false,
    AppFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
    DateTime? rateLimitUntil,
    bool clearRateLimitUntil = false,
    DiscoverFilterCatalog? filterCatalog,
    bool clearFilterCatalog = false,
    int? generation,
    DateTime? fetchedAt,
    bool clearFetchedAt = false,
  }) {
    return DiscoverState(
      query: query ?? this.query,
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      source: clearSource ? null : source ?? this.source,
      failure: clearFailure ? null : failure ?? this.failure,
      loadMoreFailure: clearLoadMoreFailure
          ? null
          : loadMoreFailure ?? this.loadMoreFailure,
      rateLimitUntil: clearRateLimitUntil
          ? null
          : rateLimitUntil ?? this.rateLimitUntil,
      filterCatalog: clearFilterCatalog
          ? null
          : filterCatalog ?? this.filterCatalog,
      generation: generation ?? this.generation,
      fetchedAt: clearFetchedAt ? null : fetchedAt ?? this.fetchedAt,
    );
  }
}
