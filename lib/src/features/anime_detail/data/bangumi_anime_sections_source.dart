import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/anime_detail/domain/anime_detail_sections.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

abstract interface class AnimeDetailSectionsSource {
  Future<List<AnimeRelation>> fetchRelations(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  });
  Future<List<AnimeCharacterCredit>> fetchCharacters(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  });
  Future<List<AnimeStaffCredit>> fetchStaff(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  });
}

final class BangumiAnimeSectionsSource implements AnimeDetailSectionsSource {
  const BangumiAnimeSectionsSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });
  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;
  @override
  Future<List<AnimeRelation>> fetchRelations(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) => _execute<List<AnimeRelation>>(
    id,
    'relations',
    forceNewGeneration,
    () async => _list(
      await _get('/v0/subjects/${id.rawId}/relations'),
    ).map(_relation).whereType<AnimeRelation>().toList(growable: false),
  );
  @override
  Future<List<AnimeCharacterCredit>> fetchCharacters(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) => _execute<List<AnimeCharacterCredit>>(
    id,
    'characters',
    forceNewGeneration,
    () async => _list(
      await _get('/v0/subjects/${id.rawId}/characters'),
    ).map(_character).whereType<AnimeCharacterCredit>().toList(growable: false),
  );
  @override
  Future<List<AnimeStaffCredit>> fetchStaff(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  }) => _execute<List<AnimeStaffCredit>>(
    id,
    'persons',
    forceNewGeneration,
    () async => _list(
      await _get('/v0/subjects/${id.rawId}/persons'),
    ).map(_staff).whereType<AnimeStaffCredit>().toList(growable: false),
  );
  Future<T> _execute<T>(
    AnimeSourceId id,
    String section,
    bool force,
    Future<T> Function() operation,
  ) => coordinator.execute<T>(
    source: NetworkSource.bangumiApi,
    key: 'GET:subject:${id.rawId}:$section',
    retryEligible: true,
    forceNewGeneration: force,
    operation: operation,
  );
  Future<Object?> _get(String path) async {
    final uri = NetworkUriPolicy.bangumiBaseUri.resolve(path);
    uriPolicy.validate(NetworkSource.bangumiApi, uri);
    try {
      return (await dio.getUri<Object?>(uri)).data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  static List<Object?> _list(Object? value) {
    if (value is List<Object?>) return value;
    if (value is Map<Object?, Object?>) {
      final data = value['data'] ?? value['results'] ?? value['items'];
      if (data is List<Object?>) return data;
    }
    throw const InvalidPayloadFailure();
  }

  static Map<Object?, Object?>? _map(Object? value) =>
      value is Map<Object?, Object?> ? value : null;
  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  static int? _int(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
  static Uri? _image(Object? value) {
    final map = _map(value);
    final raw =
        _string(map?['large']) ??
        _string(map?['medium']) ??
        _string(map?['common']);
    final uri = raw == null ? null : Uri.tryParse(raw);
    return uri != null && uri.hasScheme ? uri : null;
  }

  static AnimeRelation? _relation(Object? value) {
    final map = _map(value);
    final rawId = _int(map?['id']);
    if (rawId == null || rawId <= 0) return null;
    return AnimeRelation(
      animeId: AnimeSourceId.fromBangumiId(rawId),
      title: _string(map?['name_cn']) ?? _string(map?['name']) ?? '标题暂缺',
      relation: _string(map?['relation']),
      imageUrl: _image(map?['images']),
    );
  }

  static AnimeCharacterCredit? _character(Object? value) {
    final map = _map(value);
    final rawId = _int(map?['id']);
    if (rawId == null || rawId <= 0) return null;
    final actor = _map(map?['actor']);
    final actorId = _int(actor?['id']);
    return AnimeCharacterCredit(
      characterId: PersonSourceId.fromBangumiCharacter(rawId),
      name: _string(map?['name']) ?? '角色暂缺',
      imageUrl: _image(map?['images']),
      role: _string(map?['role']),
      voiceActorId: actorId == null
          ? null
          : PersonSourceId.fromBangumiPerson(actorId),
      voiceActorName: _string(actor?['name']),
    );
  }

  static AnimeStaffCredit? _staff(Object? value) {
    final map = _map(value);
    final rawId = _int(map?['id']);
    if (rawId == null || rawId <= 0) return null;
    return AnimeStaffCredit(
      personId: PersonSourceId.fromBangumiPerson(rawId),
      name: _string(map?['name']) ?? '人员暂缺',
      role: _string(map?['relation']) ?? _string(map?['role']),
      imageUrl: _image(map?['images']),
    );
  }
}
