import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/imports/data/import_source.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

final class BangumiImportSource implements PublicCollectionSource {
  const BangumiImportSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
    this.pageSize = 50,
  });

  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;
  final int pageSize;

  @override
  ImportSource get source => ImportSource.bangumi;

  @override
  Future<PublicAccountProfile> resolveAccount(
    String input, {
    bool forceNewGeneration = false,
  }) {
    final alias = input.trim();
    if (alias.isEmpty) throw const FormatException('Bangumi 用户名不能为空');
    final key = 'GET:/v0/users/$alias';
    return coordinator.execute<PublicAccountProfile>(
      source: NetworkSource.bangumiApi,
      key: key,
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get('/v0/users/${Uri.encodeComponent(alias)}');
        final map = _object(payload, 'Bangumi 用户资料');
        final id = _positiveInt(map['id']);
        final displayName =
            _string(map['nickname']) ?? _string(map['username']) ?? alias;
        if (id == null || displayName.isEmpty) {
          throw const InvalidPayloadFailure();
        }
        return PublicAccountProfile(
          key: PublicAccountKey(source: source, stableUserId: id.toString()),
          displayName: displayName,
          inputAlias: alias,
        );
      },
    );
  }

  @override
  Future<CollectionPage> fetchCollectionPage(
    PublicAccountProfile profile,
    int page, {
    bool forceNewGeneration = false,
  }) {
    if (profile.key.source != source) throw ArgumentError('来源不匹配');
    if (page <= 0) throw ArgumentError.value(page, 'page');
    final offset = (page - 1) * pageSize;
    final alias = profile.inputAlias.trim();
    final key =
        'GET:/v0/users/$alias/collections?limit=$pageSize&offset=$offset';
    return coordinator.execute<CollectionPage>(
      source: NetworkSource.bangumiApi,
      key: key,
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get(
          '/v0/users/${Uri.encodeComponent(alias)}/collections',
          queryParameters: <String, Object?>{
            'limit': pageSize,
            'offset': offset,
          },
        );
        return _parseCollectionPage(payload, page);
      },
    );
  }

  Future<Object?> _get(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    var uri = NetworkUriPolicy.bangumiBaseUri.resolve(path);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(
        queryParameters: queryParameters.map(
          (key, value) => MapEntry(key, '$value'),
        ),
      );
    }
    uriPolicy.validate(NetworkSource.bangumiApi, uri);
    try {
      final response = await dio.getUri<Object?>(uri);
      return response.data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  CollectionPage _parseCollectionPage(Object? payload, int page) {
    final root = switch (payload) {
      final List<Object?> list => <String, Object?>{'data': list},
      final Map<Object?, Object?> map => map.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      _ => throw const InvalidPayloadFailure(),
    };
    final rawItems = root['data'];
    if (rawItems is! List<Object?>) throw const InvalidPayloadFailure();
    final items = rawItems.map(_parseItem).toList(growable: false);
    final total = _positiveInt(root['total']);
    final hasNext = root['has_next'] is bool
        ? root['has_next'] as bool
        : root['hasNextPage'] is bool
        ? root['hasNextPage'] as bool
        : total == null
        ? items.length >= pageSize
        : page * pageSize < total;
    return CollectionPage(
      page: page,
      items: items,
      hasNextPage: hasNext,
      declaredTotal: total,
    );
  }

  PublicCollectionItem _parseItem(Object? value) {
    final map = _object(value, 'Bangumi 收藏条目');
    final subject = map['subject'] is Map<Object?, Object?>
        ? _object(map['subject'], 'Bangumi 收藏作品')
        : map;
    final id = _positiveInt(subject['id']);
    if (id == null) throw const InvalidPayloadFailure();
    final title =
        _string(subject['name_cn']) ??
        _string(subject['name']) ??
        (throw const InvalidPayloadFailure());
    final aliases = <String>[
      if (_string(subject['name']) != null) _string(subject['name'])!,
      if (_string(subject['name_cn']) != null) _string(subject['name_cn'])!,
    ].where((item) => item != title).toSet().toList(growable: false);
    final images = subject['images'] is Map<Object?, Object?>
        ? _object(subject['images'], 'Bangumi 图片')
        : const <String, Object?>{};
    final rawStatus =
        _string(map['status']) ?? _string(map['collection_status']);
    final status = _status(rawStatus);
    final watched = _nonNegativeInt(map['ep_status']) ?? 0;
    final episodes =
        _nonNegativeInt(subject['eps']) ??
        _nonNegativeInt(subject['total_episodes']);
    return PublicCollectionItem(
      observation: SourceObservation(
        sourceId: AnimeSourceId.fromBangumiId(id),
        title: title,
        aliases: aliases,
        year: _year(subject['air_date']),
        episodes: episodes,
        imageUrl: _uri(_string(images['large']) ?? _string(images['common'])),
        observedAt: DateTime.now().toUtc(),
      ),
      status: status,
      watched: watched,
      totalEpisodes: episodes,
    );
  }

  static LibraryWatchStatus _status(String? value) => switch (value) {
    'done' || 'completed' => LibraryWatchStatus.completed,
    'doing' || 'collect' || 'watching' => LibraryWatchStatus.watching,
    'on_hold' || 'paused' => LibraryWatchStatus.paused,
    'dropped' => LibraryWatchStatus.dropped,
    _ => LibraryWatchStatus.planned,
  };

  static Map<String, Object?> _object(Object? value, String label) {
    if (value is! Map<Object?, Object?>) {
      throw InvalidPayloadFailure();
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;

  static int? _positiveInt(Object? value) {
    final result = value is num ? value.toInt() : int.tryParse('$value');
    return result == null || result <= 0 ? null : result;
  }

  static int? _nonNegativeInt(Object? value) {
    final result = value is num ? value.toInt() : int.tryParse('$value');
    return result == null || result < 0 ? null : result;
  }

  static int? _year(Object? value) {
    final text = _string(value);
    return text == null || text.length < 4
        ? null
        : int.tryParse(text.substring(0, 4));
  }

  static Uri? _uri(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.hasScheme ? uri : null;
  }
}
