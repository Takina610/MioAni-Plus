import 'package:json_annotation/json_annotation.dart';

part 'bangumi_dto.g.dart';

final class BangumiCalendarResponse {
  const BangumiCalendarResponse(this.days);

  final List<BangumiCalendarDayDto> days;

  factory BangumiCalendarResponse.fromJson(Object? json) {
    if (json is! List<Object?>) {
      throw const FormatException('Bangumi calendar root must be a list');
    }
    return BangumiCalendarResponse(
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

@JsonSerializable(checked: true)
final class BangumiCalendarDayDto {
  const BangumiCalendarDayDto({required this.items});

  @JsonKey(defaultValue: <BangumiSubjectDto>[])
  final List<BangumiSubjectDto> items;

  factory BangumiCalendarDayDto.fromJson(Map<String, Object?> json) =>
      _$BangumiCalendarDayDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiCalendarDayDtoToJson(this);
}

@JsonSerializable(checked: true)
final class BangumiSubjectDto {
  const BangumiSubjectDto({
    required this.id,
    required this.name,
    this.nameCn,
    this.summary,
    this.airDate,
    this.date,
    this.platform,
    this.eps,
    this.totalEpisodes,
    this.images,
    this.rating,
    this.rank,
    this.collection,
    required this.tags,
    required this.metaTags,
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
  final String? platform;
  @JsonKey(fromJson: _nullableInt)
  final int? eps;
  @JsonKey(name: 'total_episodes', fromJson: _nullableInt)
  final int? totalEpisodes;
  final BangumiImagesDto? images;
  final BangumiRatingDto? rating;
  @JsonKey(fromJson: _nullableInt)
  final int? rank;
  final BangumiCollectionDto? collection;
  @JsonKey(defaultValue: <BangumiTagDto>[])
  final List<BangumiTagDto> tags;
  @JsonKey(name: 'meta_tags', defaultValue: <String>[])
  final List<String> metaTags;

  factory BangumiSubjectDto.fromJson(Map<String, Object?> json) =>
      _$BangumiSubjectDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiSubjectDtoToJson(this);
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
  const BangumiRatingDto({this.score, this.total, this.rank});

  @JsonKey(fromJson: _nullableDouble)
  final double? score;
  @JsonKey(fromJson: _nullableInt)
  final int? total;
  @JsonKey(fromJson: _nullableInt)
  final int? rank;

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

@JsonSerializable(checked: true)
final class BangumiTagDto {
  const BangumiTagDto({required this.name});

  @JsonKey(defaultValue: '')
  final String name;

  factory BangumiTagDto.fromJson(Map<String, Object?> json) =>
      _$BangumiTagDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiTagDtoToJson(this);
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
