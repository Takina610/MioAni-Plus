// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bangumi_calendar_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BangumiCalendarDayDto _$BangumiCalendarDayDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BangumiCalendarDayDto', json, ($checkedConvert) {
  final val = BangumiCalendarDayDto(
    weekdayId: $checkedConvert('weekday', (v) => _weekdayId(v)),
    items: $checkedConvert(
      'items',
      (v) =>
          (v as List<dynamic>?)
              ?.map(
                (e) => BangumiCalendarSubjectDto.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    ),
  );
  return val;
}, fieldKeyMap: const {'weekdayId': 'weekday'});

Map<String, dynamic> _$BangumiCalendarDayDtoToJson(
  BangumiCalendarDayDto instance,
) => <String, dynamic>{'weekday': instance.weekdayId, 'items': instance.items};

BangumiCalendarWeekdayDto _$BangumiCalendarWeekdayDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BangumiCalendarWeekdayDto', json, ($checkedConvert) {
  final val = BangumiCalendarWeekdayDto(
    id: $checkedConvert('id', (v) => _nullableInt(v)),
  );
  return val;
});

Map<String, dynamic> _$BangumiCalendarWeekdayDtoToJson(
  BangumiCalendarWeekdayDto instance,
) => <String, dynamic>{'id': instance.id};

BangumiCalendarSubjectDto _$BangumiCalendarSubjectDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'BangumiCalendarSubjectDto',
  json,
  ($checkedConvert) {
    final val = BangumiCalendarSubjectDto(
      id: $checkedConvert('id', (v) => _requiredInt(v)),
      name: $checkedConvert('name', (v) => v as String? ?? ''),
      nameCn: $checkedConvert('name_cn', (v) => v as String?),
      summary: $checkedConvert('summary', (v) => v as String?),
      airDate: $checkedConvert('air_date', (v) => v as String?),
      date: $checkedConvert('date', (v) => v as String?),
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
      collection: $checkedConvert(
        'collection',
        (v) => v == null
            ? null
            : BangumiCollectionDto.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'nameCn': 'name_cn',
    'airDate': 'air_date',
    'totalEpisodes': 'total_episodes',
  },
);

Map<String, dynamic> _$BangumiCalendarSubjectDtoToJson(
  BangumiCalendarSubjectDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'name_cn': instance.nameCn,
  'summary': instance.summary,
  'air_date': instance.airDate,
  'date': instance.date,
  'eps': instance.eps,
  'total_episodes': instance.totalEpisodes,
  'images': instance.images,
  'rating': instance.rating,
  'collection': instance.collection,
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
      );
      return val;
    });

Map<String, dynamic> _$BangumiRatingDtoToJson(BangumiRatingDto instance) =>
    <String, dynamic>{'score': instance.score};

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
