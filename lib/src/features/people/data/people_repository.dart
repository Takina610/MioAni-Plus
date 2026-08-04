import 'package:mio_ani/src/features/people/data/people_cache_store.dart';
import 'package:mio_ani/src/features/people/data/people_source.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

abstract interface class PeopleRepository {
  Future<PersonProfile> fetchProfile(
    PersonSourceId id, {
    bool forceRefresh = false,
  });
  Future<({List<PersonWork> items, bool hasMore})> fetchWorks(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  });
  Future<({List<VoiceRole> items, bool hasMore})> fetchVoiceRoles(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  });
  Future<({List<PersonComment> items, bool hasMore})> fetchComments(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  });
}

typedef PeopleNow = DateTime Function();

final class PeopleRepositoryImpl implements PeopleRepository {
  PeopleRepositoryImpl({
    required this.bangumi,
    required this.anilist,
    required this.cache,
    required this.now,
  });
  final PeopleSource bangumi;
  final PeopleSource anilist;
  final PeopleCacheStore cache;
  final PeopleNow now;

  @override
  Future<PersonProfile> fetchProfile(
    PersonSourceId id, {
    bool forceRefresh = false,
  }) async {
    PeopleCacheRecord<PersonProfile>? cached;
    if (!forceRefresh) {
      try {
        cached = await cache.readProfile(id);
      } on Object {
        cached = null;
      }
    }
    final current = now();
    if (cached != null && current.isBefore(cached.staleAt)) return cached.value;
    try {
      final profile = await _source(
        id,
      ).fetchProfile(id, forceNewGeneration: forceRefresh);
      final fetchedAt = now();
      try {
        await cache.writeProfile(
          id,
          PeopleCacheRecord(
            value: profile,
            fetchedAt: fetchedAt,
            staleAt: fetchedAt.add(const Duration(days: 7)),
            expiresAt: fetchedAt.add(const Duration(days: 30)),
          ),
        );
      } on Object {
        // A corrupt/unavailable cache must not hide a successful network result.
      }
      return profile;
    } catch (_) {
      if (cached != null && current.isBefore(cached.expiresAt)) {
        return cached.value;
      }
      rethrow;
    }
  }

  @override
  Future<({List<PersonWork> items, bool hasMore})> fetchWorks(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  }) => _source(id).fetchWorks(id, page, forceNewGeneration: forceRefresh);
  @override
  Future<({List<VoiceRole> items, bool hasMore})> fetchVoiceRoles(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  }) => _source(id).fetchVoiceRoles(id, page, forceNewGeneration: forceRefresh);
  @override
  Future<({List<PersonComment> items, bool hasMore})> fetchComments(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  }) => _source(id).fetchComments(id, page, forceNewGeneration: forceRefresh);

  PeopleSource _source(PersonSourceId id) =>
      id.source == PersonSource.bangumi ? bangumi : anilist;
}
