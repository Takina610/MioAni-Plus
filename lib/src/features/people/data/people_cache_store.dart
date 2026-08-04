import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

final class PeopleCacheRecord<T> {
  const PeopleCacheRecord({
    required this.value,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
  });
  final T value;
  final DateTime fetchedAt;
  final DateTime staleAt;
  final DateTime expiresAt;
}

abstract interface class PeopleCacheStore {
  Future<PeopleCacheRecord<PersonProfile>?> readProfile(PersonSourceId id);
  Future<void> writeProfile(
    PersonSourceId id,
    PeopleCacheRecord<PersonProfile> record,
  );
}

final class MemoryPeopleCacheStore implements PeopleCacheStore {
  final Map<PersonSourceId, PeopleCacheRecord<PersonProfile>> _profiles =
      <PersonSourceId, PeopleCacheRecord<PersonProfile>>{};
  @override
  Future<PeopleCacheRecord<PersonProfile>?> readProfile(
    PersonSourceId id,
  ) async => _profiles[id];
  @override
  Future<void> writeProfile(
    PersonSourceId id,
    PeopleCacheRecord<PersonProfile> record,
  ) async {
    _profiles[id] = record;
  }
}
