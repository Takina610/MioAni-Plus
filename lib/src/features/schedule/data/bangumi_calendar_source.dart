import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_dto.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_mapper.dart';
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
          final response = BangumiCalendarResponse.fromJson(payload);
          return <ScheduleSourceItem>[
            for (final day in response.days)
              for (final subject in day.items)
                ScheduleSourceItem(
                  // The catalogue's own mapper, so a calendar row is the same
                  // summary every other Bangumi list carries — including which
                  // cover a tile should ask for. It used to build its own, and
                  // the home page's poster grid read this one: a second mapper
                  // is a second answer to the same question.
                  anime: mapBangumiSummary(subject),
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
}
