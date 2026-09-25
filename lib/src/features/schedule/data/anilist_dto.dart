import 'package:json_annotation/json_annotation.dart';

part 'anilist_dto.g.dart';

/// Root of the AniList `Page.media` query. Parsed without a generic GraphQL
/// client so a checked, hand-written contract owns every field the schedule and
/// the home lineups consume (title, cover, episodes, score, popularity, next
/// airing and page position).
final class AniListPageResponse {
  const AniListPageResponse(this.media, {this.hasNextPage = false});

  final List<AniListMediaDto> media;

  /// Whether the source reported another page behind this one. A query that
  /// does not select `pageInfo` — the airing schedule does not — leaves this
  /// false rather than guessing, so only a paged caller may read it.
  final bool hasNextPage;

  factory AniListPageResponse.fromJson(Object? json) {
    final root = _object(json, 'AniList root');
    final data = root['data'];
    if (data == null) {
      throw const FormatException('AniList payload is missing data');
    }
    final page = _object(data, 'AniList data');
    final pageObject = page['Page'];
    if (pageObject == null) {
      throw const FormatException('AniList payload is missing Page');
    }
    final pageMap = _object(pageObject, 'AniList Page');
    final info = pageMap['pageInfo'];
    final hasNextPage = info is Map<Object?, Object?>
        ? info['hasNextPage'] == true
        : false;
    final rawMedia = pageMap['media'];
    if (rawMedia == null) {
      return AniListPageResponse(
        const <AniListMediaDto>[],
        hasNextPage: hasNextPage,
      );
    }
    if (rawMedia is! List<Object?>) {
      throw const FormatException('AniList media must be a list');
    }
    return AniListPageResponse(
      rawMedia
          .map((item) {
            final map = _object(item, 'AniList media entry');
            return AniListMediaDto.fromJson(map);
          })
          .toList(growable: false),
      hasNextPage: hasNextPage,
    );
  }

  static Map<String, Object?> _object(Object? value, String label) {
    if (value is! Map<Object?, Object?>) {
      throw FormatException('$label must be an object');
    }
    return <String, Object?>{
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }
}

@JsonSerializable(checked: true)
final class AniListMediaDto {
  const AniListMediaDto({
    required this.id,
    this.title,
    this.coverImage,
    this.episodes,
    this.averageScore,
    this.popularity,
    this.nextAiringEpisode,
  });

  @JsonKey(fromJson: _requiredInt)
  final int id;
  final AniListTitleDto? title;
  final AniListCoverImageDto? coverImage;
  @JsonKey(fromJson: _nullableInt)
  final int? episodes;
  @JsonKey(fromJson: _nullableInt)
  final int? averageScore;
  @JsonKey(fromJson: _nullableInt)
  final int? popularity;
  final AniListAiringDto? nextAiringEpisode;

  factory AniListMediaDto.fromJson(Map<String, Object?> json) =>
      _$AniListMediaDtoFromJson(json);

  Map<String, Object?> toJson() => _$AniListMediaDtoToJson(this);
}

@JsonSerializable(checked: true)
final class AniListTitleDto {
  const AniListTitleDto({this.romaji, this.english, this.native});

  final String? romaji;
  final String? english;
  final String? native;

  factory AniListTitleDto.fromJson(Map<String, Object?> json) =>
      _$AniListTitleDtoFromJson(json);

  Map<String, Object?> toJson() => _$AniListTitleDtoToJson(this);
}

@JsonSerializable(checked: true)
final class AniListCoverImageDto {
  const AniListCoverImageDto({this.large});

  final String? large;

  factory AniListCoverImageDto.fromJson(Map<String, Object?> json) =>
      _$AniListCoverImageDtoFromJson(json);

  Map<String, Object?> toJson() => _$AniListCoverImageDtoToJson(this);
}

@JsonSerializable(checked: true)
final class AniListAiringDto {
  const AniListAiringDto({required this.airingAt, this.episode});

  /// Unix seconds; converted to a local calendar time at the source boundary.
  @JsonKey(fromJson: _requiredInt)
  final int airingAt;
  @JsonKey(fromJson: _nullableInt)
  final int? episode;

  factory AniListAiringDto.fromJson(Map<String, Object?> json) =>
      _$AniListAiringDtoFromJson(json);

  Map<String, Object?> toJson() => _$AniListAiringDtoToJson(this);
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
