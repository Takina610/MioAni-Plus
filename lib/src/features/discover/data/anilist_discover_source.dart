import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/data/discover_source.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

const String discoverAniListQuery = '''
query Discover(\$page: Int, \$perPage: Int, \$search: String, \$type: MediaType, \$season: MediaSeason, \$seasonYear: Int, \$status: MediaStatus, \$genres: [String], \$sort: [MediaSort], \$scoreGreater: Int, \$scoreLesser: Int) {
  Page(page: \$page, perPage: \$perPage) {
    pageInfo { hasNextPage total }
    media(type: \$type, search: \$search, season: \$season, seasonYear: \$seasonYear, status: \$status, genre_in: \$genres, sort: \$sort, averageScore_greater: \$scoreGreater, averageScore_lesser: \$scoreLesser) {
      id
      title { romaji english native }
      coverImage { large }
      averageScore
      episodes
      popularity
      startDate { year month day }
      format
    }
  }
}
''';

final class AniListDiscoverSource implements DiscoverSource {
  const AniListDiscoverSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;

  @override
  AnimeSource get source => AnimeSource.anilist;

  @override
  Future<DiscoverPageResult> fetchPage(
    DiscoverPageRequest request, {
    bool forceNewGeneration = false,
  }) {
    final key =
        'POST:anilist-discover:${request.query.cacheKey}:page=${request.page}';
    return coordinator.execute<DiscoverPageResult>(
      source: NetworkSource.anilistApi,
      key: key,
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _post(request);
        return _map(payload, request);
      },
    );
  }

  @override
  Future<DiscoverFilterCatalog> fetchFilterCatalog({
    bool forceNewGeneration = false,
  }) async {
    return const DiscoverFilterCatalog(
      genres: <String>[
        'Action',
        'Adventure',
        'Comedy',
        'Drama',
        'Romance',
        'Sci-Fi',
        'Fantasy',
        'Mystery',
        'Sports',
        'Music',
        'School',
        'Slice of Life',
      ],
      origins: <String>['JP', 'CN', 'KR', 'US'],
      formats: <DiscoverFormat>[
        DiscoverFormat.all,
        DiscoverFormat.tv,
        DiscoverFormat.movie,
        DiscoverFormat.ova,
        DiscoverFormat.ona,
        DiscoverFormat.special,
        DiscoverFormat.music,
      ],
      isFallback: true,
    );
  }

  Future<Object?> _post(DiscoverPageRequest request) async {
    final uri = NetworkUriPolicy.anilistBaseUri;
    uriPolicy.validate(NetworkSource.anilistApi, uri);
    final query = request.query.normalized();
    try {
      final response = await dio.postUri<Object?>(
        uri,
        data: jsonEncode(<String, Object?>{
          'query': discoverAniListQuery,
          'variables': <String, Object?>{
            'page': request.page,
            'perPage': query.pageSize,
            'search': query.keyword.isEmpty ? null : query.keyword,
            'type': _type(query.format),
            'season': query.season?.name.toUpperCase(),
            'seasonYear': query.year,
            'status': _status(query.airStatus),
            'genres': query.genres.isEmpty ? null : query.genres,
            'sort': _sort(query.sort),
            'scoreGreater': query.scoreMin == null
                ? null
                : (query.scoreMin! * 10).round(),
            'scoreLesser': query.scoreMax == null
                ? null
                : (query.scoreMax! * 10).round(),
          },
        }),
        options: Options(
          headers: const <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  DiscoverPageResult _map(Object? payload, DiscoverPageRequest request) {
    if (payload is! Map<Object?, Object?>) throw const InvalidPayloadFailure();
    if (payload['errors'] is List<Object?> &&
        (payload['errors'] as List<Object?>).isNotEmpty) {
      throw const UpstreamFailure();
    }
    final data = payload['data'];
    if (data is! Map<Object?, Object?>) throw const InvalidPayloadFailure();
    final page = data['Page'];
    if (page is! Map<Object?, Object?>) throw const InvalidPayloadFailure();
    final media = page['media'];
    if (media is! List<Object?>) throw const InvalidPayloadFailure();
    final items = <AnimeSummary>[];
    for (final value in media) {
      if (value is! Map<Object?, Object?>) continue;
      final id = _int(value['id']);
      if (id == null || id <= 0) continue;
      final titles = value['title'];
      final title = titles is Map<Object?, Object?>
          ? _string(titles['romaji']) ??
                _string(titles['english']) ??
                _string(titles['native'])
          : null;
      final sourceTitle = titles is Map<Object?, Object?>
          ? _string(titles['native']) ?? ''
          : '';
      final date = value['startDate'];
      final airDate = date is Map<Object?, Object?>
          ? DateTime.tryParse(
              '${_int(date['year']) ?? 0}-${(_int(date['month']) ?? 1).toString().padLeft(2, '0')}-${(_int(date['day']) ?? 1).toString().padLeft(2, '0')}',
            )
          : null;
      items.add(
        AnimeSummary(
          id: AnimeSourceId.fromAniListId(id),
          title: title ?? '标题暂缺',
          sourceTitle: sourceTitle,
          imageUrl: _image(value['coverImage']),
          score: _double(value['averageScore']) == null
              ? null
              : _double(value['averageScore'])! / 10,
          airDate: airDate,
          episodes: _int(value['episodes']),
          popularity: _int(value['popularity']),
          summary: _string(value['description']),
        ),
      );
    }
    final info = page['pageInfo'];
    final total = info is Map<Object?, Object?> ? _int(info['total']) : null;
    final hasNext =
        info is Map<Object?, Object?> && info['hasNextPage'] == true;
    return DiscoverPageResult(
      items: items,
      page: request.page,
      source: source,
      hasMore: hasNext,
      total: total,
    );
  }

  static String? _type(DiscoverFormat format) => switch (format) {
    DiscoverFormat.tv => 'TV',
    DiscoverFormat.movie => 'MOVIE',
    DiscoverFormat.ova => 'OVA',
    DiscoverFormat.ona => 'ONA',
    DiscoverFormat.special => 'SPECIAL',
    DiscoverFormat.music => 'MUSIC',
    _ => null,
  };

  static String? _status(DiscoverAirStatus status) => switch (status) {
    DiscoverAirStatus.airing => 'RELEASING',
    DiscoverAirStatus.finished => 'FINISHED',
    DiscoverAirStatus.upcoming => 'NOT_YET_RELEASED',
    _ => null,
  };

  static List<String> _sort(DiscoverSort sort) => switch (sort) {
    DiscoverSort.relevance => <String>['SEARCH_MATCH'],
    DiscoverSort.popularity => <String>['POPULARITY_DESC'],
    DiscoverSort.score => <String>['SCORE_DESC'],
    DiscoverSort.rank => <String>['SCORE_DESC'],
    DiscoverSort.airDate => <String>['START_DATE_DESC'],
  };

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  static int? _int(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
  static double? _double(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');

  static Uri? _image(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    final raw = _string(value['large']);
    final uri = raw == null ? null : Uri.tryParse(raw);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }
}
