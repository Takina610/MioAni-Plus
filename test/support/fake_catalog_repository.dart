import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_repository.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';

final testAnimeId = AnimeSourceId.fromBangumiId(1);

final testAnimeSummary = AnimeSummary(
  id: testAnimeId,
  title: '测试动画',
  sourceTitle: 'Test Anime',
  score: 8.2,
  airDate: DateTime.utc(2026, 7, 1),
  summary: '用于确定性测试的动画简介。',
);

final testAnimeDetail = AnimeDetail(
  id: testAnimeId,
  title: '测试动画',
  sourceTitle: 'Test Anime',
  score: 8.2,
  airDate: DateTime.utc(2026, 7, 1),
  summary: '用于确定性测试的动画详情。',
  episodes: 12,
  rank: 100,
  scoreCount: 1000,
  format: 'TV',
  tags: const <String>['日常', '奇幻'],
);

CatalogSnapshot<T> testSnapshot<T>(
  T value, {
  bool isStale = false,
  AppFailure? refreshFailure,
}) {
  return CatalogSnapshot<T>(
    value: value,
    fetchedAt: DateTime.utc(2026, 7, 31, 8),
    isStale: isStale,
    refreshFailure: refreshFailure,
  );
}

final class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    Stream<CatalogSnapshot<List<AnimeSummary>>>? catalog,
    Stream<CatalogSnapshot<AnimeDetail>>? detail,
    Stream<CatalogSnapshot<List<AnimeSummary>>> Function()? catalogFactory,
    Stream<CatalogSnapshot<AnimeDetail>> Function()? detailFactory,
  }) : _catalogFactory =
           catalogFactory ??
           (() =>
               catalog ??
               Stream.value(testSnapshot(<AnimeSummary>[testAnimeSummary]))),
       _detailFactory =
           detailFactory ??
           (() => detail ?? Stream.value(testSnapshot(testAnimeDetail)));

  final Stream<CatalogSnapshot<List<AnimeSummary>>> Function() _catalogFactory;
  final Stream<CatalogSnapshot<AnimeDetail>> Function() _detailFactory;
  int catalogCalls = 0;
  int detailCalls = 0;
  bool? lastCatalogForceRefresh;
  bool? lastDetailForceRefresh;

  @override
  Stream<CatalogSnapshot<List<AnimeSummary>>> watchCatalog({
    bool forceRefresh = false,
  }) {
    catalogCalls += 1;
    lastCatalogForceRefresh = forceRefresh;
    return _catalogFactory();
  }

  @override
  Stream<CatalogSnapshot<AnimeDetail>> watchDetail(
    AnimeSourceId id, {
    bool forceRefresh = false,
  }) {
    detailCalls += 1;
    lastDetailForceRefresh = forceRefresh;
    if (id != testAnimeId) {
      return Stream<CatalogSnapshot<AnimeDetail>>.error(
        const NotFoundFailure(),
      );
    }
    return _detailFactory();
  }
}
