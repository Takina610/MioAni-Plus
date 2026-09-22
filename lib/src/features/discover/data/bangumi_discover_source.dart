import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/data/discover_source.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

final class BangumiDiscoverSource implements DiscoverSource {
  const BangumiDiscoverSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;

  @override
  AnimeSource get source => AnimeSource.bangumi;

  @override
  Future<DiscoverPageResult> fetchPage(
    DiscoverPageRequest request, {
    bool forceNewGeneration = false,
  }) {
    final key =
        'POST:/v0/search/subjects:${request.query.cacheKey}:page=${request.page}';
    return coordinator.execute<DiscoverPageResult>(
      source: NetworkSource.bangumiApi,
      key: key,
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _postSearch(request);
        return _mapResult(payload, request);
      },
    );
  }

  @override
  Future<DiscoverFilterCatalog> fetchFilterCatalog({
    bool forceNewGeneration = false,
  }) async {
    return const DiscoverFilterCatalog(
      genres: <String>[
        '动作',
        '喜剧',
        '剧情',
        '爱情',
        '科幻',
        '奇幻',
        '冒险',
        '悬疑',
        '日常',
        '校园',
        '音乐',
        '运动',
      ],
      origins: <String>['日本', '中国', '韩国', '欧美'],
      formats: <DiscoverFormat>[
        DiscoverFormat.all,
        DiscoverFormat.tv,
        DiscoverFormat.movie,
        DiscoverFormat.ova,
        DiscoverFormat.ona,
        DiscoverFormat.special,
      ],
      isFallback: true,
    );
  }

  Future<Object?> _postSearch(DiscoverPageRequest request) async {
    final query = request.query.normalized();
    // Paging travels in the query string: the endpoint ignores page/page_size
    // in the body, so a body-paged request repeats the first page forever.
    final uri = NetworkUriPolicy.bangumiBaseUri
        .resolve('/v0/search/subjects')
        .replace(
          queryParameters: <String, String>{
            'limit': '${query.pageSize}',
            'offset': '${(request.page - 1) * query.pageSize}',
          },
        );
    uriPolicy.validate(NetworkSource.bangumiApi, uri);
    final filter = <String, Object?>{
      if (query.genres.isNotEmpty) 'tag': query.genres,
      if (query.year != null)
        'air_date': <String>['>=${query.year}-01-01', '<=${query.year}-12-31'],
      if (query.format != DiscoverFormat.all)
        'type': <int>[_bangumiType(query.format)],
      if (query.airStatus != DiscoverAirStatus.all)
        'air_status': <int>[_bangumiAirStatus(query.airStatus)],
      if (query.scoreMin != null) 'rating': <String>['>=${query.scoreMin}'],
      if (query.scoreMax != null) 'rating': <String>['<=${query.scoreMax}'],
      if (query.origin != null) 'platform': <String>[query.origin!],
    };
    try {
      final response = await dio.postUri<Object?>(
        uri,
        data: <String, Object?>{
          'keyword': query.keyword,
          'sort': _bangumiSort(query.sort),
          'filter': filter,
        },
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  DiscoverPageResult _mapResult(Object? payload, DiscoverPageRequest request) {
    if (payload is! Map<Object?, Object?>) throw const InvalidPayloadFailure();
    // The P1 subjects search answers with `data`/`total`; `results`/`list`
    // belongs to the legacy /search/subject endpoint and never appears here.
    final result = payload['data'];
    if (result is! List<Object?>) throw const InvalidPayloadFailure();
    final items = <AnimeSummary>[];
    for (final value in result) {
      if (value is! Map<Object?, Object?>) continue;
      final id = _int(value['id']);
      if (id == null || id <= 0) continue;
      final title =
          _string(value['name_cn']) ?? _string(value['name']) ?? '标题暂缺';
      final sourceTitle = _string(value['name']) ?? title;
      final imageUrl = _imageUrl(value['images']);
      // Subjects carry `date`; `air_date` only appears on calendar rows.
      final airDate = DateTime.tryParse(
        _string(value['date']) ?? _string(value['air_date']) ?? '',
      );
      final rating = value['rating'];
      final score = rating is Map<Object?, Object?>
          ? _double(rating['score'])
          : _double(value['score']);
      final collection = value['collection'];
      final popularity = collection is Map<Object?, Object?>
          ? _int(collection['collect'])
          : null;
      items.add(
        AnimeSummary(
          id: AnimeSourceId.fromBangumiId(id),
          title: title,
          sourceTitle: sourceTitle,
          imageUrl: imageUrl,
          score: score,
          airDate: airDate,
          episodes: _int(value['eps']) ?? _int(value['total_episodes']),
          popularity: popularity,
          summary: _string(value['summary']),
        ),
      );
    }
    final total = _int(payload['total']);
    return DiscoverPageResult(
      items: items,
      page: request.page,
      source: source,
      hasMore: total == null
          ? items.length >= request.query.pageSize
          : request.page * request.query.pageSize < total,
      total: total,
    );
  }

  static int _bangumiType(DiscoverFormat format) => switch (format) {
    DiscoverFormat.tv => 2,
    DiscoverFormat.movie => 3,
    DiscoverFormat.ova || DiscoverFormat.ona => 1,
    DiscoverFormat.special => 6,
    _ => 2,
  };

  static int _bangumiAirStatus(DiscoverAirStatus status) => switch (status) {
    DiscoverAirStatus.airing => 1,
    DiscoverAirStatus.finished => 2,
    DiscoverAirStatus.upcoming => 3,
    _ => 0,
  };

  static String _bangumiSort(DiscoverSort sort) => switch (sort) {
    DiscoverSort.relevance => 'match',
    DiscoverSort.popularity => 'heat',
    DiscoverSort.score || DiscoverSort.rank => 'rank',
    // The subjects endpoint accepts only match/heat/rank/score; asking for a
    // date order answers 400 "sort not supported", so keep the request valid.
    DiscoverSort.airDate => 'match',
  };

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  static int? _int(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
  static double? _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  static Uri? _imageUrl(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final raw =
        _string(value['large']) ??
        _string(value['medium']) ??
        _string(value['common']);
    final uri = raw == null ? null : Uri.tryParse(raw);
    return uri != null && uri.hasScheme ? uri : null;
  }
}
