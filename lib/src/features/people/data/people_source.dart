import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

abstract interface class PeopleSource {
  PersonSource get source;
  Future<PersonProfile> fetchProfile(
    PersonSourceId id, {
    bool forceNewGeneration = false,
  });
  Future<({List<PersonWork> items, bool hasMore})> fetchWorks(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  });
  Future<({List<VoiceRole> items, bool hasMore})> fetchVoiceRoles(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  });
  Future<({List<PersonComment> items, bool hasMore})> fetchComments(
    PersonSourceId id,
    int page, {
    bool forceNewGeneration = false,
  });
}
