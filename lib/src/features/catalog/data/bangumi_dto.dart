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
  const BangumiCalendarDayDto({required this.weekdayId, required this.items});

  /// `weekday.id` (1=Mon … 7=Sun). The catalogue has no use for it — it reads
  /// this endpoint for the covers — but the weekly schedule anchors every row
  /// by it, which is why the shared day carries it.
  @JsonKey(name: 'weekday', fromJson: _weekdayId)
  final int weekdayId;

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
    this.nsfw = false,
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

  /// Adult flag. The calendar does not carry it at all, the subject endpoints
  /// do, so a missing or unexpected value reads as "not adult".
  @JsonKey(fromJson: _flag, defaultValue: false)
  final bool nsfw;
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
  const BangumiImagesDto({
    this.large,
    this.common,
    this.medium,
    this.grid,
    this.small,
  });

  final String? large;
  final String? common;
  final String? medium;
  final String? grid;
  final String? small;

  /// The largest cover this payload carries.
  ///
  /// Which of the five sizes an entry publishes varies: the endpoints that
  /// answer with a full subject usually have the original, while a subject
  /// created before its art is uploaded — or one read back from a listing —
  /// may only have the smaller renditions. Returning null here would drop a
  /// cover that exists, so every size is tried, largest first.
  String? get best => _firstText(<String?>[large, common, medium, grid, small]);

  /// The rendition for a grid tile or a list thumbnail: the same picture the
  /// full-size cover shows, at the size a list actually displays.
  ///
  /// Bangumi publishes `common` for its own list pages, so this asks for what
  /// the source itself considers a list cover rather than downloading the full
  /// original and scaling it down to a 100px tile. The full-size cover is not
  /// offered here at all: a source that carries only one rendition is served by
  /// [best] at the call site.
  String? get thumbnail => _firstText(<String?>[common, medium, grid, small]);

  factory BangumiImagesDto.fromJson(Map<String, Object?> json) =>
      _$BangumiImagesDtoFromJson(json);

  Map<String, Object?> toJson() => _$BangumiImagesDtoToJson(this);
}

String? _firstText(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
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

int _weekdayId(Object? value) {
  if (value is Map<Object?, Object?>) {
    final parsed = _nullableInt(value['id']);
    if (parsed != null) return parsed;
  }
  throw const FormatException('Bangumi calendar day is missing weekday.id');
}

int _requiredInt(Object? value) {
  return _nullableInt(value) ??
      (throw const FormatException('Expected a required integer'));
}

bool _flag(Object? value) => value == true;

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
