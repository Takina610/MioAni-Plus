import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

final class PersonProfile {
  const PersonProfile({
    required this.id,
    required this.name,
    this.aliases = const <String>[],
    this.imageUrl,
    this.summary,
    this.gender,
    this.birthDate,
    this.bloodType,
    this.careers = const <String>[],
    this.infobox = const <String, String>{},
  });

  final PersonSourceId id;
  final String name;
  final List<String> aliases;
  final Uri? imageUrl;
  final String? summary;
  final String? gender;
  final DateTime? birthDate;
  final String? bloodType;
  final List<String> careers;
  final Map<String, String> infobox;
}

final class PersonWork {
  const PersonWork({
    required this.animeId,
    required this.title,
    this.imageUrl,
    this.role,
  });

  final AnimeSourceId animeId;
  final String title;
  final Uri? imageUrl;
  final String? role;
}

final class VoiceRole {
  const VoiceRole({
    required this.characterId,
    required this.characterName,
    this.personId,
    this.personName,
  });

  final PersonSourceId characterId;
  final String characterName;
  final PersonSourceId? personId;
  final String? personName;
}

final class PersonComment {
  const PersonComment({
    required this.id,
    required this.userName,
    required this.body,
    this.createdAt,
    this.rating,
  });

  final String id;
  final String userName;
  final String body;
  final DateTime? createdAt;
  final int? rating;
}

final class AnimeRelation {
  const AnimeRelation({
    required this.animeId,
    required this.title,
    this.relation,
    this.imageUrl,
  });

  final AnimeSourceId animeId;
  final String title;
  final String? relation;
  final Uri? imageUrl;
}

final class AnimeCharacterCredit {
  const AnimeCharacterCredit({
    required this.characterId,
    required this.name,
    this.imageUrl,
    this.role,
    this.voiceActorId,
    this.voiceActorName,
  });

  final PersonSourceId characterId;
  final String name;
  final Uri? imageUrl;
  final String? role;
  final PersonSourceId? voiceActorId;
  final String? voiceActorName;
}

final class AnimeStaffCredit {
  const AnimeStaffCredit({
    required this.personId,
    required this.name,
    this.role,
    this.imageUrl,
  });

  final PersonSourceId personId;
  final String name;
  final String? role;
  final Uri? imageUrl;
}

final class TranslationBlock {
  const TranslationBlock({
    required this.source,
    required this.text,
    this.language,
  });

  final String source;
  final String text;
  final String? language;
}

enum SectionStatus {
  idle,
  loading,
  fresh,
  stale,
  loadingMore,
  errorEmpty,
  errorWithContent,
  empty,
}

final class SectionState<T> {
  const SectionState({
    this.status = SectionStatus.idle,
    this.value,
    this.error,
    this.page = 0,
    this.hasMore = false,
    this.fetchedAt,
  });

  final SectionStatus status;
  final T? value;
  final Object? error;
  final int page;
  final bool hasMore;
  final DateTime? fetchedAt;

  bool get hasContent => value != null;

  SectionState<T> copyWith({
    SectionStatus? status,
    T? value,
    Object? error,
    bool clearError = false,
    bool clearValue = false,
    int? page,
    bool? hasMore,
    DateTime? fetchedAt,
  }) {
    return SectionState<T>(
      status: status ?? this.status,
      value: clearValue ? null : value ?? this.value,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
