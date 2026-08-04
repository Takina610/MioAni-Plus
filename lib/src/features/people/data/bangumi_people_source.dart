import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/people/data/people_source.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

final class BangumiPeopleSource implements PeopleSource {
  const BangumiPeopleSource({
    required this.dio,
    required this.coordinator,
    this.uriPolicy = const NetworkUriPolicy(),
  });
  final Dio dio;
  final RequestCoordinator coordinator;
  final NetworkUriPolicy uriPolicy;

  @override
  PersonSource get source => PersonSource.bangumi;

  @override
  Future<PersonProfile> fetchProfile(
    PersonSourceId id, {
    bool forceNewGeneration = false,
  }) {
    final path = id.isCharacter
        ? '/v0/characters/${id.rawId}'
        : '/v0/persons/${id.rawId}';
    return coordinator.execute<PersonProfile>(
      source: NetworkSource.bangumiApi,
      key: 'GET:$path',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get(path);
        if (payload is! Map<Object?, Object?>) {
          throw const InvalidPayloadFailure();
        }
        return _profile(payload, id);
      },
    );
  }

  @override
  Future<({List<PersonWork> items, bool hasMore})> fetchWorks(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) {
    final path =
        '${id.isCharacter ? '/v0/characters' : '/v0/persons'}/${id.rawId}/subjects?page=$page';
    return coordinator.execute<({List<PersonWork> items, bool hasMore})>(
      source: NetworkSource.bangumiApi,
      key: 'GET:$path',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get(path);
        return (items: _works(payload), hasMore: _hasMore(payload));
      },
    );
  }

  @override
  Future<({List<VoiceRole> items, bool hasMore})> fetchVoiceRoles(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) {
    final path =
        '${id.isCharacter ? '/v0/characters' : '/v0/persons'}/${id.rawId}/characters?page=$page';
    return coordinator.execute<({List<VoiceRole> items, bool hasMore})>(
      source: NetworkSource.bangumiApi,
      key: 'GET:$path',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get(path);
        return (items: _roles(payload), hasMore: _hasMore(payload));
      },
    );
  }

  @override
  Future<({List<PersonComment> items, bool hasMore})> fetchComments(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) {
    final path =
        '/v0/${id.isCharacter ? 'characters' : 'persons'}/${id.rawId}/comments?page=$page';
    return coordinator.execute<({List<PersonComment> items, bool hasMore})>(
      source: NetworkSource.bangumiApi,
      key: 'GET:$path',
      retryEligible: true,
      forceNewGeneration: forceNewGeneration,
      operation: () async {
        final payload = await _get(path);
        return (items: _comments(payload), hasMore: _hasMore(payload));
      },
    );
  }

  Future<Object?> _get(String path) async {
    final uri = NetworkUriPolicy.bangumiBaseUri.resolve(path);
    uriPolicy.validate(NetworkSource.bangumiApi, uri);
    try {
      return (await dio.getUri<Object?>(uri)).data;
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  PersonProfile _profile(Map<Object?, Object?> map, PersonSourceId id) {
    final name = _string(map['name']) ?? _string(map['name_cn']) ?? '姓名暂缺';
    final infobox = _stringMap(map['infobox']);
    final aliases = <String>{
      ..._strings(map['aliases']),
      ...infobox.entries
          .where(
            (entry) => entry.key.contains('别名') || entry.key.contains('昵称'),
          )
          .expand((entry) => _strings(entry.value)),
    }.toList(growable: false);
    return PersonProfile(
      id: id,
      name: name,
      aliases: aliases,
      imageUrl: _image(map['images']),
      summary: _string(map['summary']),
      gender: _string(map['gender']),
      birthDate: _date(map['birth_year'], map['birth_month'], map['birth_day']),
      bloodType: _string(map['blood_type']),
      careers: _strings(map['career']),
      infobox: infobox,
    );
  }

  List<PersonWork> _works(Object? payload) {
    return _list(payload)
        .map((value) {
          final map = _map(value);
          final id = _int(map['id']);
          if (id == null || id <= 0) return null;
          return PersonWork(
            animeId: AnimeSourceId.fromBangumiId(id),
            title: _string(map['name_cn']) ?? _string(map['name']) ?? '标题暂缺',
            imageUrl: _image(map['images']),
            role: _string(map['role']),
          );
        })
        .whereType<PersonWork>()
        .toList(growable: false);
  }

  List<VoiceRole> _roles(Object? payload) {
    return _list(payload)
        .map((value) {
          final map = _map(value);
          final id = _int(map['id']);
          if (id == null || id <= 0) return null;
          final actor = _mapOrNull(map['actor']);
          final actorId = _int(actor?['id']);
          return VoiceRole(
            characterId: PersonSourceId.fromBangumiCharacter(id),
            characterName: _string(map['name']) ?? '角色暂缺',
            personId: actorId == null
                ? null
                : PersonSourceId.fromBangumiPerson(actorId),
            personName: _string(actor?['name']),
          );
        })
        .whereType<VoiceRole>()
        .toList(growable: false);
  }

  List<PersonComment> _comments(Object? payload) {
    return _list(payload)
        .map((value) {
          final map = _map(value);
          final id = _string(map['id']) ?? _int(map['id'])?.toString();
          final body = _string(map['comment']) ?? _string(map['text']);
          if (id == null || body == null) return null;
          return PersonComment(
            id: id,
            userName: _string(_mapOrNull(map['user'])?['nickname']) ?? '匿名',
            body: body,
            createdAt: DateTime.tryParse(_string(map['created_at']) ?? ''),
            rating: _int(map['rating']),
          );
        })
        .whereType<PersonComment>()
        .toList(growable: false);
  }

  static bool _hasMore(Object? payload) {
    final map = _mapOrNull(payload);
    final page = _mapOrNull(map?['page']);
    return page?['has_next'] == true || _list(payload).length >= 20;
  }

  static List<Object?> _list(Object? payload) {
    if (payload is List<Object?>) return payload;
    if (payload is Map<Object?, Object?>) {
      final data = payload['data'] ?? payload['results'] ?? payload['items'];
      if (data is List<Object?>) return data;
    }
    throw const InvalidPayloadFailure();
  }

  static Map<Object?, Object?> _map(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    throw const InvalidPayloadFailure();
  }

  static Map<Object?, Object?>? _mapOrNull(Object? value) =>
      value is Map<Object?, Object?> ? value : null;
  static String? _string(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  static int? _int(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
  static List<String> _strings(Object? value) => value is List<Object?>
      ? value
            .whereType<String>()
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .toList(growable: false)
      : value is String
      ? <String>[value]
      : const <String>[];
  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map<Object?, Object?>) return const <String, String>{};
    return <String, String>{
      for (final e in value.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  }

  static Uri? _image(Object? value) {
    final map = _mapOrNull(value);
    final raw =
        _string(map?['large']) ??
        _string(map?['medium']) ??
        _string(map?['common']);
    final uri = raw == null ? null : Uri.tryParse(raw);
    return uri != null && uri.scheme == 'https' ? uri : null;
  }

  static DateTime? _date(Object? year, Object? month, Object? day) {
    final y = _int(year), m = _int(month), d = _int(day);
    return y == null
        ? null
        : DateTime.tryParse(
            '$y-${(m ?? 1).toString().padLeft(2, '0')}-${(d ?? 1).toString().padLeft(2, '0')}',
          );
  }
}
