import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

enum HomeSectionStatus { loading, ready, failed }

/// One independently failing home partition: a failed partition never blocks
/// the brand shell.
final class HomeSection<T> {
  const HomeSection.loading()
    : status = HomeSectionStatus.loading,
      value = null,
      failure = null,
      isStale = false,
      fetchedAt = null,
      refreshFailure = null;

  const HomeSection.ready({
    required this.value,
    this.isStale = false,
    this.fetchedAt,
    this.refreshFailure,
  }) : status = HomeSectionStatus.ready,
       failure = null;

  const HomeSection.failed(this.failure)
    : status = HomeSectionStatus.failed,
      value = null,
      isStale = false,
      fetchedAt = null,
      refreshFailure = null;

  final HomeSectionStatus status;
  final T? value;
  final AppFailure? failure;

  /// True when [value] came from an expired or cross-date cache.
  final bool isStale;
  final DateTime? fetchedAt;

  /// Non-null when cached content is shown but the latest refresh failed.
  final AppFailure? refreshFailure;

  bool get isLoading => status == HomeSectionStatus.loading;
}

/// Catalog-derived home content (brand hero and season posters).
final class HomeCatalogContent {
  const HomeCatalogContent({required this.hero, required this.trending});

  final List<AnimeSummary> hero;
  final List<AnimeSummary> trending;
}

/// Immutable home state consumed by widgets. Already succeeded content stays
/// visible while a refresh is in flight or has failed.
final class HomeSnapshot {
  const HomeSnapshot({
    this.catalog = const HomeSection<HomeCatalogContent>.loading(),
  });

  final HomeSection<HomeCatalogContent> catalog;

  bool get isLoading => catalog.isLoading;
}
