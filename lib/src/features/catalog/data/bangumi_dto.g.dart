// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bangumi_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BangumiCalendarDayDto _$BangumiCalendarDayDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BangumiCalendarDayDto', json, ($checkedConvert) {
  final val = BangumiCalendarDayDto(
    items: $checkedConvert(
      'items',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) => BangumiSubjectDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    ),
  );
  return val;
});

Map<String, dynamic> _$BangumiCalendarDayDtoToJson(
  BangumiCalendarDayDto instance,
) => <String, dynamic>{'items': instance.items};

BangumiSubjectDto _$BangumiSubjectDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'BangumiSubjectDto',
  json,
  ($checkedConvert) {
    final val = BangumiSubjectDto(
      id: $checkedConvert('id', (v) => _requiredInt(v)),
      name: $checkedConvert('name', (v) => v as String? ?? ''),
      nameCn: $checkedConvert('name_cn', (v) => v as String?),
      summary: $checkedConvert('summary', (v) => v as String?),
      airDate: $checkedConvert('air_date', (v) => v as String?),
      date: $checkedConvert('date', (v) => v as String?),
      platform: $checkedConvert('platform', (v) => v as String?),
      eps: $checkedConvert('eps', (v) => _nullableInt(v)),
      totalEpisodes: $checkedConvert('total_episodes', (v) => _nullableInt(v)),
      images: $checkedConvert(
        'images',
        (v) => v == null
            ? null
            : BangumiImagesDto.fromJson(v as Map<String, dynamic>),
      ),
      rating: $checkedConvert(
        'rating',
        (v) => v == null
            ? null
            : BangumiRatingDto.fromJson(v as Map<String, dynamic>),
      ),
      rank: $checkedConvert('rank', (v) => _nullableInt(v)),
      collection: $checkedConvert(
        'collection',
        (v) => v == null
            ? null
            : BangumiCollectionDto.fromJson(v as Map<String, dynamic>),
      ),
      tags: $checkedConvert(
        'tags',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => BangumiTagDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      ),
      metaTags: $checkedConvert(
        'meta_tags',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'nameCn': 'name_cn',
    'airDate': 'air_date',
    'totalEpisodes': 'total_episodes',
    'metaTags': 'meta_tags',
  },
);

Map<String, dynamic> _$BangumiSubjectDtoToJson(BangumiSubjectDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'name_cn': instance.nameCn,
      'summary': instance.summary,
      'air_date': instance.airDate,
      'date': instance.date,
      'platform': instance.platform,
      'eps': instance.eps,
      'total_episodes': instance.totalEpisodes,
      'images': instance.images,
      'rating': instance.rating,
      'rank': instance.rank,
      'collection': instance.collection,
      'tags': instance.tags,
      'meta_tags': instance.metaTags,
    };

BangumiImagesDto _$BangumiImagesDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BangumiImagesDto', json, ($checkedConvert) {
      final val = BangumiImagesDto(
        large: $checkedConvert('large', (v) => v as String?),
        common: $checkedConvert('common', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$BangumiImagesDtoToJson(BangumiImagesDto instance) =>
    <String, dynamic>{'large': instance.large, 'common': instance.common};

BangumiRatingDto _$BangumiRatingDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BangumiRatingDto', json, ($checkedConvert) {
      final val = BangumiRatingDto(
        score: $checkedConvert('score', (v) => _nullableDouble(v)),
        total: $checkedConvert('total', (v) => _nullableInt(v)),
        rank: $checkedConvert('rank', (v) => _nullableInt(v)),
      );
      return val;
    });

Map<String, dynamic> _$BangumiRatingDtoToJson(BangumiRatingDto instance) =>
    <String, dynamic>{
      'score': instance.score,
      'total': instance.total,
      'rank': instance.rank,
    };

BangumiCollectionDto _$BangumiCollectionDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BangumiCollectionDto', json, ($checkedConvert) {
  final val = BangumiCollectionDto(
    doing: $checkedConvert('doing', (v) => _nullableInt(v)),
  );
  return val;
});

Map<String, dynamic> _$BangumiCollectionDtoToJson(
  BangumiCollectionDto instance,
) => <String, dynamic>{'doing': instance.doing};

BangumiTagDto _$BangumiTagDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BangumiTagDto', json, ($checkedConvert) {
      final val = BangumiTagDto(
        name: $checkedConvert('name', (v) => v as String? ?? ''),
      );
      return val;
    });

Map<String, dynamic> _$BangumiTagDtoToJson(BangumiTagDto instance) =>
    <String, dynamic>{'name': instance.name};
