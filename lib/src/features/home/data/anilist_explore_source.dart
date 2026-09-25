import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/explore_source.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_dto.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_media_mapper.dart';

/// Static GraphQL query for AniList's all-time popularity ranking.
///
/// Exploring means walking past the current season the home page already
/// carries, so this page is the whole catalogue rather than one season. Sorting
/// is by popularity — the order the season list above it reads in, so the two
/// sections speak the same language — and adult entries are kept out of a
/// lineup browsed from the home page.
const String anilistExploreQuery = '''
query ExploreLineup(\$page: Int, \$perPage: Int) {
  Page(page: \$page, perPage: \$perPage) {
    pageInfo { hasNextPage }
    media(type: ANIME, sort: POPULARITY_DESC, isAdult: false) {
      id
      title { romaji english native }
      coverImage { large }
      episodes
      averageScore
      popularity
    }
  }
}
''';

/// The paged AniList ranking behind the home explore feed.
///
/// It stands behind the Bangumi heat ranking: the fallback for when the home
/// page's own source cannot answer, and the one ranking it can be read from
/// when Bangumi has nothing.
final class AniListExploreSource implements ExploreAnimeSource {
  const AniListExploreSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
    this.pageSize = 30,
  });

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;

  /// AniList's page maximum is 50. `30` keeps one page to a screenful or two of
  /// posters, so the feed reads as a continuous scroll rather than a dump.
  final int pageSize;

  @override
  AnimeSource get source => AnimeSource.anilist;

  @override
  Future<HomeExplorePage> fetchPage(
    int page, {
    bool forceNewGeneration = false,
  }) {
    return coordinator.execute<HomeExplorePage>(
      source: NetworkSource.anilistApi,
      key: 'POST:anilist-explore:$page',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final uri = NetworkUriPolicy.anilistBaseUri;
        uriPolicy.validate(NetworkSource.anilistApi, uri);
        final Object? payload;
        try {
          final response = await dio.postUri<Object?>(
            uri,
            data: jsonEncode(<String, Object?>{
              'query': anilistExploreQuery,
              'variables': <String, Object?>{'page': page, 'perPage': pageSize},
            }),
            options: Options(
              headers: const <String, String>{
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );
          payload = response.data;
        } on DioException catch (error) {
          throw mapDioFailure(error);
        }

        try {
          final parsed = AniListPageResponse.fromJson(payload);
          return HomeExplorePage(
            items: <AnimeSummary>[
              for (final dto in parsed.media) anilistMediaSummary(dto),
            ],
            page: page,
            hasMore: parsed.hasNextPage,
            source: source,
          );
        } on AppFailure {
          rethrow;
        } on Object {
          throw const InvalidPayloadFailure();
        }
      },
    );
  }
}
