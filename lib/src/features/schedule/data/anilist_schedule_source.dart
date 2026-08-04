import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_dto.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_sources.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_merger.dart';

/// AniList broadcast seasons used by the `MediaSeason` GraphQL enum.
enum AniListSeason {
  winter('WINTER'),
  spring('SPRING'),
  summer('SUMMER'),
  fall('FALL');

  const AniListSeason(this.apiValue);

  final String apiValue;
}

typedef AniListClock = DateTime Function();

typedef AniListSeasonResolver =
    ({AniListSeason season, int year}) Function(DateTime now);

/// Northern-hemisphere anime season for a local calendar date.
({AniListSeason season, int year}) currentAniListSeason(DateTime now) {
  final season = switch (now.month) {
    1 || 2 || 3 => AniListSeason.winter,
    4 || 5 || 6 => AniListSeason.spring,
    7 || 8 || 9 => AniListSeason.summer,
    _ => AniListSeason.fall,
  };
  return (season: season, year: now.year);
}

/// Static GraphQL season query. Kept as one fixture so request/response shapes
/// stay in lockstep; only the fields C4 consumes are selected.
const String anilistSeasonQuery = '''
query AiringSchedule(\$season: MediaSeason, \$seasonYear: Int, \$page: Int, \$perPage: Int) {
  Page(page: \$page, perPage: \$perPage) {
    media(type: ANIME, season: \$season, seasonYear: \$seasonYear, sort: POPULARITY_DESC) {
      id
      title { romaji english native }
      coverImage { large }
      episodes
      averageScore
      popularity
      nextAiringEpisode { airingAt episode }
    }
  }
}
''';

final class AniListScheduleSource implements AniListAiringSource {
  const AniListScheduleSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
    this.clock = DateTime.now,
    this.seasonResolver = currentAniListSeason,
  });

  static const int _pageSize = 30;

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;
  final AniListClock clock;
  final AniListSeasonResolver seasonResolver;

  /// Fetches the current season's airing donors. Entries without a
  /// `nextAiringEpisode` cannot contribute a time, so they are dropped at the
  /// boundary; the rest become enrichment donors for the Bangumi baseline.
  @override
  Future<List<AniListAiringEntry>> fetchAiringEntries({
    bool forceNewGeneration = false,
  }) {
    final resolved = seasonResolver(clock());
    return coordinator.execute<List<AniListAiringEntry>>(
      source: NetworkSource.anilistApi,
      key: 'POST:anilist:${resolved.year}:${resolved.season.name}',
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
              'query': anilistSeasonQuery,
              'variables': <String, Object?>{
                'season': resolved.season.apiValue,
                'seasonYear': resolved.year,
                'page': 1,
                'perPage': _pageSize,
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
          final media = AniListPageResponse.fromJson(payload).media;
          return <AniListAiringEntry>[
            for (final dto in media)
              if (dto.nextAiringEpisode case final airing?)
                AniListAiringEntry(
                  anime: _summary(dto),
                  airingAt: DateTime.fromMillisecondsSinceEpoch(
                    airing.airingAt * 1000,
                  ),
                ),
          ];
        } on AppFailure {
          rethrow;
        } on Object {
          throw const InvalidPayloadFailure();
        }
      },
    );
  }

  AnimeSummary _summary(AniListMediaDto dto) {
    final title = dto.title;
    final display = title?.romaji ?? title?.english ?? title?.native ?? '';
    final source = title?.native ?? title?.english ?? '';
    return AnimeSummary(
      id: AnimeSourceId.fromAniListId(dto.id),
      title: display,
      sourceTitle: source == display ? '' : source,
      imageUrl: _httpsUri(dto.coverImage?.large),
      score: dto.averageScore == null ? null : dto.averageScore! / 10,
      episodes: dto.episodes,
      popularity: dto.popularity,
    );
  }

  Uri? _httpsUri(String? value) {
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
