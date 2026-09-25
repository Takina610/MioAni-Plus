import 'dart:async';

import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/data/discover_repository.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

import 'fake_catalog_repository.dart';

/// Deterministic [DiscoverRepository] stand-in that records how the page drove
/// the search pipeline.
final class FakeDiscoverRepository implements DiscoverRepository {
  FakeDiscoverRepository({
    List<AnimeSummary>? items,
    this.failure,
    this.hasMore = false,
    this.pageGate,
  }) : items = items ?? <AnimeSummary>[testAnimeSummary];

  final List<AnimeSummary> items;
  final Object? failure;
  final bool hasMore;

  /// When set, every page waits on it before answering, which is how a test
  /// looks at the page while a search is still in flight.
  Completer<void>? pageGate;

  int fetchPageCalls = 0;
  int fetchFilterCatalogCalls = 0;
  DiscoverQuery? lastQuery;
  AnimeSource? lastLockedSource;
  bool? lastForceRefresh;

  @override
  AnimeSource chooseSource(DiscoverQuery query, {AnimeSource? lockedSource}) {
    return lockedSource ?? AnimeSource.bangumi;
  }

  @override
  Future<DiscoverPageResult> fetchPage(
    DiscoverQuery query, {
    required int page,
    AnimeSource? lockedSource,
    bool forceRefresh = false,
  }) async {
    fetchPageCalls += 1;
    lastQuery = query;
    lastLockedSource = lockedSource;
    lastForceRefresh = forceRefresh;
    final gate = pageGate;
    if (gate != null) await gate.future;
    final error = failure;
    if (error != null) throw error;
    return DiscoverPageResult(
      items: page == 1 ? items : const <AnimeSummary>[],
      page: page,
      source: lockedSource ?? AnimeSource.bangumi,
      hasMore: hasMore,
      total: items.length,
      fetchedAt: DateTime.utc(2026, 9, 21, 8),
    );
  }

  @override
  Future<DiscoverFilterCatalog> fetchFilterCatalog(
    DiscoverQuery query, {
    AnimeSource? lockedSource,
    bool forceRefresh = false,
  }) async {
    fetchFilterCatalogCalls += 1;
    return const DiscoverFilterCatalog();
  }
}
