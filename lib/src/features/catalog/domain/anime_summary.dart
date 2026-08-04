import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

class AnimeSummary {
  const AnimeSummary({
    required this.id,
    required this.title,
    required this.sourceTitle,
    this.imageUrl,
    this.score,
    this.airDate,
    this.summary,
    this.episodes,
    this.popularity,
  });

  final AnimeSourceId id;
  final String title;
  final String sourceTitle;
  final Uri? imageUrl;
  final double? score;
  final DateTime? airDate;
  final String? summary;

  /// Known episode count for display (`更新至第X话`) and AniList enrichment.
  final int? episodes;

  /// Public follow/popularity counter used for stable schedule ordering.
  final int? popularity;

  String get sourceLabel => switch (id.source) {
    AnimeSource.bangumi => 'Bangumi',
    AnimeSource.anilist => 'AniList',
  };

  @override
  bool operator ==(Object other) {
    return other is AnimeSummary &&
        other.id == id &&
        other.title == title &&
        other.sourceTitle == sourceTitle &&
        other.imageUrl == imageUrl &&
        other.score == score &&
        other.airDate == airDate &&
        other.summary == summary &&
        other.episodes == episodes &&
        other.popularity == popularity;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    sourceTitle,
    imageUrl,
    score,
    airDate,
    summary,
    episodes,
    popularity,
  );
}

final class AnimeDetail extends AnimeSummary {
  const AnimeDetail({
    required super.id,
    required super.title,
    required super.sourceTitle,
    super.imageUrl,
    super.score,
    super.airDate,
    super.summary,
    super.episodes,
    super.popularity,
    this.rank,
    this.scoreCount,
    this.format,
    this.tags = const <String>[],
  });

  final int? rank;
  final int? scoreCount;
  final String? format;
  final List<String> tags;
}
