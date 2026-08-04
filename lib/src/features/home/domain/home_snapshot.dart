import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';

enum HomeSectionStatus { loading, ready, failed }

/// One independently failing home partition. A failed partition never blocks
/// the brand shell or the other partition's already-succeeded content.
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

/// Catalog-derived home content (brand hero, season picks and trending).
final class HomeCatalogContent {
  const HomeCatalogContent({
    required this.hero,
    required this.recommended,
    required this.trending,
  });

  final List<AnimeSummary> hero;
  final List<AnimeSummary> recommended;
  final List<AnimeSummary> trending;
}

/// Schedule-derived home content (recent updates rail + week preview).
final class HomeScheduleContent {
  const HomeScheduleContent({required this.recent, required this.days});

  final List<ScheduleItem> recent;
  final List<ScheduleDay> days;
}

/// Immutable home state consumed by widgets. The brand hero and already
/// succeeded partitions remain visible even when a sibling partition failed.
final class HomeSnapshot {
  const HomeSnapshot({
    this.catalog = const HomeSection<HomeCatalogContent>.loading(),
    this.schedule = const HomeSection<HomeScheduleContent>.loading(),
  });

  final HomeSection<HomeCatalogContent> catalog;
  final HomeSection<HomeScheduleContent> schedule;

  bool get isLoading => catalog.isLoading && schedule.isLoading;

  HomeSnapshot copyWith({
    HomeSection<HomeCatalogContent>? catalog,
    HomeSection<HomeScheduleContent>? schedule,
  }) {
    return HomeSnapshot(
      catalog: catalog ?? this.catalog,
      schedule: schedule ?? this.schedule,
    );
  }
}
