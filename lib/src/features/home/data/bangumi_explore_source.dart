import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_dto.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_mapper.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/explore_source.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';

/// Bangumi's all-time heat ranking, the primary ranking behind the home explore
/// feed.
///
/// It is the subjects search with no keyword and no filter, sorted by `heat`:
/// the same endpoint the discover page searches through, asked for its default
/// ranking instead of a query. Bangumi publishes this list in Chinese, which is
/// the language the rest of the home page reads in.
final class BangumiExploreSource implements ExploreAnimeSource {
  const BangumiExploreSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
    this.pageSize = onePage,
  });

  /// The most this endpoint answers with, however large a `limit` it is asked
  /// for: asking for more returns 20 entries, and the offset of the next page
  /// would then skip everything between. Paging therefore advances by 20.
  static const int onePage = 20;

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;
  final int pageSize;

  @override
  AnimeSource get source => AnimeSource.bangumi;

  @override
  Future<HomeExplorePage> fetchPage(
    int page, {
    bool forceNewGeneration = false,
  }) {
    final offset = (page - 1) * pageSize;
    return coordinator.execute<HomeExplorePage>(
      source: NetworkSource.bangumiApi,
      key: 'POST:/v0/search/subjects:heat:$offset',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _post(offset);
        return _map(payload, page, offset);
      },
    );
  }

  Future<Object?> _post(int offset) async {
    final uri = NetworkUriPolicy.bangumiBaseUri
        .resolve('/v0/search/subjects')
        .replace(
          queryParameters: <String, String>{
            'limit': '$pageSize',
            'offset': '$offset',
          },
        );
    uriPolicy.validate(NetworkSource.bangumiApi, uri);
    try {
      final response = await dio.postUri<Object?>(
        uri,
        data: const <String, Object?>{
          'keyword': '',
          'sort': 'heat',
          'filter': <String, Object?>{},
        },
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  HomeExplorePage _map(Object? payload, int page, int offset) {
    if (payload is! Map<Object?, Object?>) throw const InvalidPayloadFailure();
    final raw = payload['data'];
    if (raw is! List<Object?>) throw const InvalidPayloadFailure();
    final items = <AnimeSummary>[];
    for (final value in raw) {
      final map = _object(value);
      if (map == null) continue;
      final BangumiSubjectDto dto;
      try {
        dto = BangumiSubjectDto.fromJson(map);
      } on Object {
        // One unreadable entry must not cost the reader the whole page.
        continue;
      }
      // Adult entries are kept out of a lineup browsed from the home page, the
      // way the AniList fallback keeps them out of its ranking.
      if (dto.nsfw) continue;
      items.add(mapBangumiSummary(dto));
    }
    final total = _int(payload['total']);
    return HomeExplorePage(
      items: items,
      page: page,
      hasMore: total != null
          ? offset + items.length < total
          : items.length >= pageSize,
      source: source,
    );
  }

  static Map<String, Object?>? _object(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    return <String, Object?>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  static int? _int(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}
