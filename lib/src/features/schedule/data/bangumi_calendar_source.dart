import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/data/bangumi_calendar_dto.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_sources.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

/// Bangumi `/calendar` week template source.
///
/// The API anchors items in fixed weekday buckets but does not expose airing
/// times, so every mapped row is untimed (`待定`) here; the repository later
/// fills known `HH:mm` from matching AniList donors.
final class BangumiCalendarSource implements ScheduleCalendarSource {
  const BangumiCalendarSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });

  static const String _requestKey = 'GET:/calendar';

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;

  @override
  Future<List<ScheduleSourceItem>> fetchCalendar({
    bool forceNewGeneration = false,
  }) {
    return coordinator.execute<List<ScheduleSourceItem>>(
      source: NetworkSource.bangumiApi,
      key: _requestKey,
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final uri = NetworkUriPolicy.bangumiBaseUri.resolve('/calendar');
        uriPolicy.validate(NetworkSource.bangumiApi, uri);
        final Object? payload;
        try {
          final response = await dio.getUri<Object?>(uri);
          payload = response.data;
        } on DioException catch (error) {
          throw mapDioFailure(error);
        }

        try {
          final response = BangumiCalendarResponseDto.fromJson(payload);
          return <ScheduleSourceItem>[
            for (final day in response.days)
              for (final subject in day.items)
                ScheduleSourceItem(
                  anime: _summary(subject),
                  weekday: ScheduleWeekday.fromBangumiId(day.weekdayId),
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

  AnimeSummary _summary(BangumiCalendarSubjectDto dto) {
    final title = _firstText(<String?>[dto.nameCn, dto.name]) ?? '';
    final sourceTitle = _firstText(<String?>[dto.name, dto.nameCn]) ?? '';
    return AnimeSummary(
      id: AnimeSourceId.fromBangumiId(dto.id),
      title: title,
      sourceTitle: sourceTitle == title ? '' : sourceTitle,
      imageUrl: _imageUri(dto.images?.large ?? dto.images?.common),
      score: dto.rating?.score,
      airDate: _date(dto.airDate ?? dto.date),
      summary: _cleanText(dto.summary),
      episodes: dto.eps ?? dto.totalEpisodes,
      popularity: dto.collection?.doing,
    );
  }

  String? _firstText(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  String? _cleanText(String? value) {
    if (value == null) return null;
    final cleaned = value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp('<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  DateTime? _date(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value.trim());
  }

  Uri? _imageUri(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final upgraded = value.trim().replaceFirst(RegExp(r'^http://'), 'https://');
    final uri = Uri.tryParse(upgraded);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }
}
