import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/imports/data/import_source.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

const String resolveAniListPublicUserQuery = r'''
query ResolvePublicUser($name: String) {
  User(name: $name) { id name }
}
''';

const String fetchAniListPublicCollectionQuery = r'''
query PublicMediaList($userId: Int!, $page: Int!, $perPage: Int!) {
  Page(page: $page, perPage: $perPage) {
    pageInfo { hasNextPage total currentPage lastPage }
    mediaList(userId: $userId, type: ANIME) {
      status
      progress
      media {
        id
        title { romaji english native }
        episodes
        startDate { year }
        coverImage { large }
      }
    }
  }
}
''';

final class AniListImportSource implements PublicCollectionSource {
  const AniListImportSource({
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
  ImportSource get source => ImportSource.anilist;

  @override
  Future<PublicAccountProfile> resolveAccount(
    String input, {
    bool forceNewGeneration = false,
  }) {
    final alias = input.trim();
    if (alias.isEmpty) throw const FormatException('AniList 用户名不能为空');
    return coordinator.execute<PublicAccountProfile>(
      source: NetworkSource.anilistApi,
      key: 'POST:resolve-public-user:$alias',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _post(
          resolveAniListPublicUserQuery,
          <String, Object?>{'name': alias},
        );
        final user = _userFromPayload(payload);
        final id = _positiveInt(user['id']);
        final name = _string(user['name']);
        if (id == null || name == null) throw const InvalidPayloadFailure();
        return PublicAccountProfile(
          key: PublicAccountKey(source: source, stableUserId: id.toString()),
          displayName: name,
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
    final userId = int.tryParse(profile.key.stableUserId);
    if (userId == null || userId <= 0) {
      throw const FormatException('AniList 用户 ID 无效');
    }
    return coordinator.execute<CollectionPage>(
      source: NetworkSource.anilistApi,
      key: 'POST:public-collection:$userId:$page:$pageSize',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _post(
          fetchAniListPublicCollectionQuery,
          <String, Object?>{
            'userId': userId,
            'page': page,
            'perPage': pageSize,
          },
        );
        return _parsePage(payload, page);
      },
    );
  }

  Future<Object?> _post(String query, Map<String, Object?> variables) async {
    final uri = NetworkUriPolicy.anilistBaseUri;
    uriPolicy.validate(NetworkSource.anilistApi, uri);
    try {
      final response = await dio.postUri<Object?>(
        uri,
        data: jsonEncode(<String, Object?>{
          'query': query,
          'variables': variables,
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

  Map<String, Object?> _userFromPayload(Object? payload) {
    final root = _object(payload);
    if (_errors(root)) throw const UpstreamFailure();
    final data = _object(root['data']);
    final user = data['User'];
    if (user == null) throw const NotFoundFailure();
    return _object(user);
  }

  CollectionPage _parsePage(Object? payload, int page) {
    final root = _object(payload);
    if (_errors(root)) throw const UpstreamFailure();
    final data = _object(root['data']);
    final pageRoot = _object(data['Page']);
    final info = _object(pageRoot['pageInfo']);
    final raw = pageRoot['mediaList'];
    if (raw is! List<Object?>) throw const InvalidPayloadFailure();
    final items = raw.map(_parseItem).toList(growable: false);
    final hasNext = info['hasNextPage'];
    if (hasNext is! bool) throw const InvalidPayloadFailure();
    return CollectionPage(
      page: page,
      items: items,
      hasNextPage: hasNext,
      declaredTotal: _positiveInt(info['total']),
    );
  }

  PublicCollectionItem _parseItem(Object? value) {
    final map = _object(value);
    final media = _object(map['media']);
    final id = _positiveInt(media['id']);
    if (id == null) throw const InvalidPayloadFailure();
    final titleRoot = _object(media['title']);
    final title =
        _string(titleRoot['native']) ??
        _string(titleRoot['romaji']) ??
        _string(titleRoot['english']);
    if (title == null) throw const InvalidPayloadFailure();
    final aliases = <String>{
      if (_string(titleRoot['romaji']) != null) _string(titleRoot['romaji'])!,
      if (_string(titleRoot['english']) != null) _string(titleRoot['english'])!,
      if (_string(titleRoot['native']) != null) _string(titleRoot['native'])!,
    }..remove(title);
    final episodes = _positiveInt(media['episodes']);
    final progress = _nonNegativeInt(map['progress']) ?? 0;
    final rawStatus = _string(map['status']);
    final startDate = media['startDate'] is Map<Object?, Object?>
        ? _object(media['startDate'])
        : const <String, Object?>{};
    final coverImage = media['coverImage'] is Map<Object?, Object?>
        ? _object(media['coverImage'])
        : const <String, Object?>{};
    return PublicCollectionItem(
      observation: SourceObservation(
        sourceId: AnimeSourceId.fromAniListId(id),
        title: title,
        aliases: aliases.toList(growable: false),
        year: _positiveInt(startDate['year']),
        episodes: episodes,
        imageUrl: _uri(_string(coverImage['large'])),
        observedAt: DateTime.now().toUtc(),
      ),
      status: _status(rawStatus),
      watched: progress,
      totalEpisodes: episodes,
    );
  }

  static LibraryWatchStatus _status(String? value) => switch (value) {
    'COMPLETED' => LibraryWatchStatus.completed,
    'CURRENT' || 'REPEATING' => LibraryWatchStatus.watching,
    'PAUSED' => LibraryWatchStatus.paused,
    'DROPPED' => LibraryWatchStatus.dropped,
    _ => LibraryWatchStatus.planned,
  };

  static bool _errors(Map<String, Object?> root) {
    final errors = root['errors'];
    return errors is List<Object?> && errors.isNotEmpty;
  }

  static Map<String, Object?> _object(Object? value) {
    if (value is! Map<Object?, Object?>) throw const InvalidPayloadFailure();
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

  static Uri? _uri(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.hasScheme ? uri : null;
  }
}
