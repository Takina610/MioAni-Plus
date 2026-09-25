import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// A slice of the home explore feed: the ranking window a source answered with,
/// the page it came from, and whether the ranking continues past it.
///
/// The repository hands out the *whole* feed it has cached so far in the same
/// shape, where [page] is the last page fetched — the caller then never has to
/// merge pages itself.
final class HomeExplorePage {
  const HomeExplorePage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.source,
  });

  final List<AnimeSummary> items;
  final int page;

  /// True while the feed may still grow: the source has another page behind
  /// this one and the feed has not reached its cap.
  final bool hasMore;

  /// The data source whose ranking this page was read from.
  ///
  /// A feed pages within one ranking: page numbers only line up against the
  /// list they were counted on, so the source travels with the content.
  final AnimeSource source;
}

enum HomeExploreStatus { loading, ready, loadingMore, failed }

/// Immutable explore state consumed by the home page. Content already fetched
/// stays visible while the next page is in flight or has failed.
final class HomeExploreState {
  const HomeExploreState({
    this.status = HomeExploreStatus.loading,
    this.items = const <AnimeSummary>[],
    this.page = 0,
    this.hasMore = false,
    this.failure,
    this.loadMoreFailure,
  });

  final HomeExploreStatus status;
  final List<AnimeSummary> items;
  final int page;
  final bool hasMore;

  /// Failure of the first page, which leaves the section without content.
  final AppFailure? failure;

  /// Failure of a later page: [items] still hold everything loaded before it.
  final AppFailure? loadMoreFailure;

  bool get isLoading => status == HomeExploreStatus.loading;
  bool get isLoadingMore => status == HomeExploreStatus.loadingMore;
  bool get hasContent => items.isNotEmpty;
}
