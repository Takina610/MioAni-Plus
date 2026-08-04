import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/people/data/people_source.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

const String peopleAniListQuery = r'''
query People(\$characterId: Int, \$staffId: Int, \$page: Int, \$perPage: Int) {
  character(id: \$characterId) { id name { full native alternative } image { large } description gender dateOfBirth { year month day } bloodType media(page: \$page, perPage: \$perPage) { nodes { id title { romaji english native } coverImage { large } } pageInfo { hasNextPage } } }
  staff(id: \$staffId) { id name { full native alternative } image { large } description gender dateOfBirth { year month day } bloodType primaryOccupations staffMedia(page: \$page, perPage: \$perPage) { nodes { id title { romaji english native } coverImage { large } } pageInfo { hasNextPage } } characters(page: \$page, perPage: \$perPage) { nodes { id name { full native } image { large } } pageInfo { hasNextPage } } }
}
''';

final class AniListPeopleSource implements PeopleSource {
  const AniListPeopleSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });
  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;
  @override
  PersonSource get source => PersonSource.anilist;

  @override
  Future<PersonProfile> fetchProfile(
    PersonSourceId id, {
    bool forceNewGeneration = false,
  }) => coordinator.execute<PersonProfile>(
    source: NetworkSource.anilistApi,
    key: 'POST:anilist-person:$id.value',
    retryEligible: true,
    forceNewGeneration: forceNewGeneration,
    operation: () async => _profile(await _root(id), id),
  );

  @override
  Future<({List<PersonWork> items, bool hasMore})> fetchWorks(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) => coordinator.execute<({List<PersonWork> items, bool hasMore})>(
    source: NetworkSource.anilistApi,
    key: 'POST:anilist-works:$id.value:$page',
    retryEligible: true,
    forceNewGeneration: forceNewGeneration,
    operation: () async {
      final root = await _root(id, page: page);
      final media = _map(root['media'] ?? root['staffMedia']);
      final items = _list(
        media['nodes'],
      ).map(_work).whereType<PersonWork>().toList(growable: false);
      return (
        items: items,
        hasMore: _map(media['pageInfo'])['hasNextPage'] == true,
      );
    },
  );

  @override
  Future<({List<VoiceRole> items, bool hasMore})> fetchVoiceRoles(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) => coordinator.execute<({List<VoiceRole> items, bool hasMore})>(
    source: NetworkSource.anilistApi,
    key: 'POST:anilist-roles:$id.value:$page',
    retryEligible: true,
    forceNewGeneration: forceNewGeneration,
    operation: () async {
      final root = await _root(id, page: page);
      final characters = _map(root['characters']);
      final items = _list(
        characters['nodes'],
      ).map(_role).whereType<VoiceRole>().toList(growable: false);
      return (
        items: items,
        hasMore: _map(characters['pageInfo'])['hasNextPage'] == true,
      );
    },
  );

  @override
  Future<({List<PersonComment> items, bool hasMore})> fetchComments(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) async => (items: const <PersonComment>[], hasMore: false);

  Future<Map<Object?, Object?>> _root(PersonSourceId id, {int page = 1}) async {
    final payload = await _post(id, page: page);
    if (payload is! Map<Object?, Object?>) {
      throw const InvalidPayloadFailure();
    }
    final errors = payload['errors'];
    if (errors is List<Object?> && errors.isNotEmpty) {
      throw const UpstreamFailure();
    }
    final data = payload['data'];
    if (data is! Map<Object?, Object?>) {
      throw const InvalidPayloadFailure();
    }
    final root = data[id.isCharacter ? 'character' : 'staff'];
    if (root is! Map<Object?, Object?>) {
      throw const NotFoundFailure();
    }
    return root;
  }

  Future<Object?> _post(PersonSourceId id, {required int page}) async {
    final uri = NetworkUriPolicy.anilistBaseUri;
    uriPolicy.validate(NetworkSource.anilistApi, uri);
    try {
      final response = await dio.postUri<Object?>(
        uri,
        data: jsonEncode(<String, Object?>{
          'query': peopleAniListQuery,
          'variables': <String, Object?>{
            'characterId': id.isCharacter ? id.rawId : null,
            'staffId': id.isPerson ? id.rawId : null,
            'page': page,
            'perPage': 20,
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

  static PersonProfile _profile(Map<Object?, Object?> map, PersonSourceId id) {
    final name = _map(map['name']);
    final date = _map(map['dateOfBirth']);
    return PersonProfile(
      id: id,
      name: _string(name['full']) ?? _string(name['native']) ?? '姓名暂缺',
      aliases: _strings(name['alternative']),
      imageUrl: _image(map['image']),
      summary: _string(map['description']),
      gender: _string(map['gender']),
      birthDate: _date(date['year'], date['month'], date['day']),
      bloodType: _string(map['bloodType']),
      careers: _strings(map['primaryOccupations']),
    );
  }

  static PersonWork? _work(Object? value) {
    final map = _mapOrNull(value);
    final rawId = _int(map?['id']);
    if (rawId == null || rawId <= 0) {
      return null;
    }
    final title = _map(map?['title']);
    return PersonWork(
      animeId: AnimeSourceId.fromAniListId(rawId),
      title:
          _string(title['english']) ??
          _string(title['romaji']) ??
          _string(title['native']) ??
          '标题暂缺',
      imageUrl: _image(map?['coverImage']),
    );
  }

  static VoiceRole? _role(Object? value) {
    final map = _mapOrNull(value);
    final rawId = _int(map?['id']);
    if (rawId == null || rawId <= 0) {
      return null;
    }
    final name = _map(map?['name']);
    return VoiceRole(
      characterId: PersonSourceId.fromAniListCharacter(rawId),
      characterName: _string(name['full']) ?? _string(name['native']) ?? '角色暂缺',
    );
  }

  static Map<Object?, Object?> _map(Object? value) =>
      value is Map<Object?, Object?> ? value : const <Object?, Object?>{};
  static Map<Object?, Object?>? _mapOrNull(Object? value) =>
      value is Map<Object?, Object?> ? value : null;
  static List<Object?> _list(Object? value) =>
      value is List<Object?> ? value : const <Object?>[];
  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  static int? _int(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
  static List<String> _strings(Object? value) => value is List<Object?>
      ? value
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
      : const <String>[];
  static Uri? _image(Object? value) {
    final raw = _string(_mapOrNull(value)?['large']);
    final uri = raw == null ? null : Uri.tryParse(raw);
    return uri != null && uri.scheme == 'https' ? uri : null;
  }

  static DateTime? _date(Object? year, Object? month, Object? day) {
    final y = _int(year);
    if (y == null) return null;
    return DateTime.tryParse(
      '$y-${(_int(month) ?? 1).toString().padLeft(2, '0')}-${(_int(day) ?? 1).toString().padLeft(2, '0')}',
    );
  }
}
