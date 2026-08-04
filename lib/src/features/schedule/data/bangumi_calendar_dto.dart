import 'package:json_annotation/json_annotation.dart';

part 'bangumi_calendar_dto.g.dart';

/// Root of `GET /calendar` — a list of weekday buckets.
final class BangumiCalendarResponseDto {
  const BangumiCalendarResponseDto(this.days);

  final List<BangumiCalendarDayDto> days;

  factory BangumiCalendarResponseDto.fromJson(Object? json) {
    if (json is! List<Object?>) {
      throw const FormatException('Bangumi calendar root must be a list');
    }
    return BangumiCalendarResponseDto(
      json
          .map((item) {
            if (item is! Map<String, Object?>) {
              throw const FormatException(
                'Bangumi calendar day must be an object',
              );
            }
            return BangumiCalendarDayDto.fromJson(item);
          })
          .toList(growable: false),
    );
  }
}

/// One weekday bucket. The `weekday.id` (1=Mon … 7=Sun) is required because it
/// anchors the item into the fixed weekly template.
@JsonSerializable(checked: true)
final class BangumiCalendarDayDto {
  const BangumiCalendarDayDto({required this.weekdayId, required this.items});

  @JsonKey(name: 'weekday', fromJson: _weekdayId)
  final int weekdayId;

  @JsonKey(defaultValue: <BangumiCalendarSubjectDto>[])
  final List<BangumiCalendarSubjectDto> items;

  factory BangumiCalendarDayDto.fromJson(Map<String, Object?> json) =>
      _$BangumiCalendarDayDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiCalendarDayDtoToJson(this);
}

@JsonSerializable(checked: true)
final class BangumiCalendarWeekdayDto {
  const BangumiCalendarWeekdayDto({this.id});

  @JsonKey(fromJson: _nullableInt)
  final int? id;

  factory BangumiCalendarWeekdayDto.fromJson(Map<String, Object?> json) =>
      _$BangumiCalendarWeekdayDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiCalendarWeekdayDtoToJson(this);
}

/// Reuses the catalog subject shape plus the fields C4 needs (episodes and
/// public doing count) without changing the catalog DTO.
@JsonSerializable(checked: true)
final class BangumiCalendarSubjectDto {
  const BangumiCalendarSubjectDto({
    required this.id,
    required this.name,
    this.nameCn,
    this.summary,
    this.airDate,
    this.date,
    this.eps,
    this.totalEpisodes,
    this.images,
    this.rating,
    this.collection,
  });

  @JsonKey(fromJson: _requiredInt)
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(name: 'name_cn')
  final String? nameCn;
  final String? summary;
  @JsonKey(name: 'air_date')
  final String? airDate;
  final String? date;
  @JsonKey(fromJson: _nullableInt)
  final int? eps;
  @JsonKey(name: 'total_episodes', fromJson: _nullableInt)
  final int? totalEpisodes;
  final BangumiImagesDto? images;
  final BangumiRatingDto? rating;
  final BangumiCollectionDto? collection;

  factory BangumiCalendarSubjectDto.fromJson(Map<String, Object?> json) =>
      _$BangumiCalendarSubjectDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiCalendarSubjectDtoToJson(this);
}

@JsonSerializable(checked: true)
final class BangumiImagesDto {
  const BangumiImagesDto({this.large, this.common});

  final String? large;
  final String? common;

  factory BangumiImagesDto.fromJson(Map<String, Object?> json) =>
      _$BangumiImagesDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiImagesDtoToJson(this);
}

@JsonSerializable(checked: true)
final class BangumiRatingDto {
  const BangumiRatingDto({this.score});

  @JsonKey(fromJson: _nullableDouble)
  final double? score;

  factory BangumiRatingDto.fromJson(Map<String, Object?> json) =>
      _$BangumiRatingDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiRatingDtoToJson(this);
}

@JsonSerializable(checked: true)
final class BangumiCollectionDto {
  const BangumiCollectionDto({this.doing});

  @JsonKey(fromJson: _nullableInt)
  final int? doing;

  factory BangumiCollectionDto.fromJson(Map<String, Object?> json) =>
      _$BangumiCollectionDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiCollectionDtoToJson(this);
}

int _weekdayId(Object? value) {
  if (value is Map<Object?, Object?>) {
    final id = value['id'];
    final parsed = _nullableInt(id);
    if (parsed != null) return parsed;
  }
  throw const FormatException('Bangumi calendar day is missing weekday.id');
}

int _requiredInt(Object? value) {
  return _nullableInt(value) ??
      (throw const FormatException('Expected a required integer'));
}

int? _nullableInt(Object? value) {
  return switch (value) {
    null => null,
    final int number => number,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null,
  };
}

double? _nullableDouble(Object? value) {
  return switch (value) {
    null => null,
    final num number => number.toDouble(),
    final String text => double.tryParse(text),
    _ => null,
  };
}
