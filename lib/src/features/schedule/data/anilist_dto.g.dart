// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anilist_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AniListMediaDto _$AniListMediaDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AniListMediaDto', json, ($checkedConvert) {
      final val = AniListMediaDto(
        id: $checkedConvert('id', (v) => _requiredInt(v)),
        title: $checkedConvert(
          'title',
          (v) => v == null
              ? null
              : AniListTitleDto.fromJson(v as Map<String, dynamic>),
        ),
        coverImage: $checkedConvert(
          'coverImage',
          (v) => v == null
              ? null
              : AniListCoverImageDto.fromJson(v as Map<String, dynamic>),
        ),
        episodes: $checkedConvert('episodes', (v) => _nullableInt(v)),
        averageScore: $checkedConvert('averageScore', (v) => _nullableInt(v)),
        popularity: $checkedConvert('popularity', (v) => _nullableInt(v)),
        nextAiringEpisode: $checkedConvert(
          'nextAiringEpisode',
          (v) => v == null
              ? null
              : AniListAiringDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AniListMediaDtoToJson(AniListMediaDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'coverImage': instance.coverImage,
      'episodes': instance.episodes,
      'averageScore': instance.averageScore,
      'popularity': instance.popularity,
      'nextAiringEpisode': instance.nextAiringEpisode,
    };

AniListTitleDto _$AniListTitleDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AniListTitleDto', json, ($checkedConvert) {
      final val = AniListTitleDto(
        romaji: $checkedConvert('romaji', (v) => v as String?),
        english: $checkedConvert('english', (v) => v as String?),
        native: $checkedConvert('native', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AniListTitleDtoToJson(AniListTitleDto instance) =>
    <String, dynamic>{
      'romaji': instance.romaji,
      'english': instance.english,
      'native': instance.native,
    };

AniListCoverImageDto _$AniListCoverImageDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AniListCoverImageDto', json, ($checkedConvert) {
  final val = AniListCoverImageDto(
    large: $checkedConvert('large', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$AniListCoverImageDtoToJson(
  AniListCoverImageDto instance,
) => <String, dynamic>{'large': instance.large};

AniListAiringDto _$AniListAiringDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AniListAiringDto', json, ($checkedConvert) {
      final val = AniListAiringDto(
        airingAt: $checkedConvert('airingAt', (v) => _requiredInt(v)),
        episode: $checkedConvert('episode', (v) => _nullableInt(v)),
      );
      return val;
    });

Map<String, dynamic> _$AniListAiringDtoToJson(AniListAiringDto instance) =>
    <String, dynamic>{
      'airingAt': instance.airingAt,
      'episode': instance.episode,
    };
