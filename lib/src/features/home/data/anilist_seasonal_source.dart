import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/data/seasonal_source.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_dto.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_media_mapper.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_schedule_source.dart';

/// Static GraphQL season query for AniList's own season ranking.
///
/// The season and year come from the API's own season filter, so every entry is
/// a member of the season by construction and no client-side date filter is
/// needed. Sorting is by popularity — the order the home season lists read in —
/// and adult entries are kept out of a browsable lineup.
const String anilistSeasonalQuery = '''
query SeasonalLineup(\$season: MediaSeason, \$seasonYear: Int, \$page: Int, \$perPage: Int) {
  Page(page: \$page, perPage: \$perPage) {
    media(type: ANIME, season: \$season, seasonYear: \$seasonYear, sort: POPULARITY_DESC, isAdult: false) {
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

/// AniList's current-season lineup, the fallback behind the home season list
/// when the Bangumi calendar has nothing for the season or is unreachable.
final class AniListSeasonalSource implements SeasonalAnimeSource {
  const AniListSeasonalSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
    this.clock = DateTime.now,
    this.seasonResolver = currentAniListSeason,
    this.pageSize = 50,
  });

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;
  final AniListClock clock;
  final AniListSeasonResolver seasonResolver;

  /// One page is the whole lineup on purpose: the home page reads a hero and a
  /// poster grid out of this list, and `50` is AniList's page maximum.
  final int pageSize;

  @override
  Future<List<AnimeSummary>> fetchSeason({bool forceNewGeneration = false}) {
    final resolved = seasonResolver(clock());
    return coordinator.execute<List<AnimeSummary>>(
      source: NetworkSource.anilistApi,
      key: 'POST:anilist-seasonal:${resolved.year}:${resolved.season.name}',
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
              'query': anilistSeasonalQuery,
              'variables': <String, Object?>{
                'season': resolved.season.apiValue,
                'seasonYear': resolved.year,
                'page': 1,
                'perPage': pageSize,
              },
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
          return <AnimeSummary>[
            for (final dto in AniListPageResponse.fromJson(payload).media)
              anilistMediaSummary(dto),
          ];
        } on AppFailure {
          rethrow;
        } on Object {
          throw const InvalidPayloadFailure();
        }
      },
    );
  }
}
