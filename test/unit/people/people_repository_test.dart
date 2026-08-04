import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/people/data/people_cache_store.dart';
import 'package:mio_ani/src/features/people/data/people_repository.dart';
import 'package:mio_ani/src/features/people/data/people_source.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

final class _FakeSource implements PeopleSource {
  _FakeSource(this.profileFactory);
  Future<PersonProfile> Function() profileFactory;
  int profileCalls = 0;
  @override
  PersonSource get source => PersonSource.bangumi;
  @override
  Future<PersonProfile> fetchProfile(
    PersonSourceId id, {
    bool forceNewGeneration = false,
  }) {
    profileCalls++;
    return profileFactory();
  }

  @override
  Future<({List<PersonWork> items, bool hasMore})> fetchWorks(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) async => (items: const <PersonWork>[], hasMore: false);
  @override
  Future<({List<VoiceRole> items, bool hasMore})> fetchVoiceRoles(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) async => (items: const <VoiceRole>[], hasMore: false);
  @override
  Future<({List<PersonComment> items, bool hasMore})> fetchComments(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  }) async => (items: const <PersonComment>[], hasMore: false);
}

final class _ThrowingCache implements PeopleCacheStore {
  @override
  Future<PeopleCacheRecord<PersonProfile>?> readProfile(
    PersonSourceId id,
  ) async => throw StateError('corrupt');
  @override
  Future<void> writeProfile(
    PersonSourceId id,
    PeopleCacheRecord<PersonProfile> record,
  ) async => throw StateError('read-only');
}

void main() {
  final id = PersonSourceId.fromBangumiPerson(1);
  PersonProfile profile(String name) => PersonProfile(id: id, name: name);

  test('uses fresh profile cache and source selection', () async {
    var now = DateTime(2026, 8, 4);
    final source = _FakeSource(() async => profile('网络'));
    final cache = MemoryPeopleCacheStore();
    final repository = PeopleRepositoryImpl(
      bangumi: source,
      anilist: source,
      cache: cache,
      now: () => now,
    );
    final first = await repository.fetchProfile(id);
    final second = await repository.fetchProfile(id);
    expect(first.name, '网络');
    expect(second.name, '网络');
    expect(source.profileCalls, 1);
    now = now.add(const Duration(days: 8));
    final stale = await repository.fetchProfile(id);
    expect(stale.name, '网络');
    expect(source.profileCalls, 2);
  });

  test(
    'falls back to stale data inside the maximum downgrade window',
    () async {
      var now = DateTime(2026, 8, 4);
      final source = _FakeSource(() async => profile('初始'));
      final repository = PeopleRepositoryImpl(
        bangumi: source,
        anilist: source,
        cache: MemoryPeopleCacheStore(),
        now: () => now,
      );
      await repository.fetchProfile(id);
      now = now.add(const Duration(days: 8));
      source.profileFactory = () async => throw const OfflineFailure();
      final fallback = await repository.fetchProfile(id);
      expect(fallback.name, '初始');
    },
  );

  test(
    'isolates corrupt cache and returns a successful network profile',
    () async {
      final source = _FakeSource(() async => profile('恢复'));
      final repository = PeopleRepositoryImpl(
        bangumi: source,
        anilist: source,
        cache: _ThrowingCache(),
        now: DateTime.now,
      );
      final result = await repository.fetchProfile(id);
      expect(result.name, '恢复');
      expect(source.profileCalls, 1);
    },
  );
}
