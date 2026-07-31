import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_dto.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_mapper.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_source.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

final class BangumiCatalogSource implements CatalogSource {
  const BangumiCatalogSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;

  static const int _maximumCatalogItems = 60;

  @override
  Future<List<AnimeSummary>> fetchCatalog({bool forceNewGeneration = false}) {
    return coordinator.execute<List<AnimeSummary>>(
      source: NetworkSource.bangumiApi,
      key: 'GET:/calendar',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get('/calendar');
        try {
          final response = BangumiCalendarResponse.fromJson(payload);
          final unique = <AnimeSourceId, AnimeSummary>{};
          for (final day in response.days) {
            for (final item in day.items) {
              final summary = mapBangumiSummary(item);
              unique.putIfAbsent(summary.id, () => summary);
            }
          }
          final items = unique.values.toList(growable: false)
            ..sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
          return items.take(_maximumCatalogItems).toList(growable: false);
        } on AppFailure {
          rethrow;
        } on Object {
          throw const InvalidPayloadFailure();
        }
      },
    );
  }

  @override
  Future<AnimeDetail> fetchDetail(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) {
    return coordinator.execute<AnimeDetail>(
      source: NetworkSource.bangumiApi,
      key: 'GET:/v0/subjects/${id.rawId}',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get('/v0/subjects/${id.rawId}');
        if (payload is! Map<String, Object?>) {
          throw const InvalidPayloadFailure();
        }
        try {
          final detail = mapBangumiDetail(BangumiSubjectDto.fromJson(payload));
          if (detail.id != id) throw const InvalidPayloadFailure();
          return detail;
        } on AppFailure {
          rethrow;
        } on Object {
          throw const InvalidPayloadFailure();
        }
      },
    );
  }

  Future<Object?> _get(String relativePath) async {
    final uri = NetworkUriPolicy.bangumiBaseUri.resolve(relativePath);
    uriPolicy.validate(NetworkSource.bangumiApi, uri);
    try {
      final response = await dio.getUri<Object?>(uri);
      return response.data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}
