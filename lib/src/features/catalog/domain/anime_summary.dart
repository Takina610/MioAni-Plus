import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

/// The country a source files a work under.
///
/// Bangumi publishes this in a subject's `meta_tags` — `日本` for a Japanese
/// work, `中国` for a Chinese one — and it is the one thing that can tell a
/// Chinese title from a Japanese one written in nothing but kanji. Looking at
/// the characters cannot: `万古至尊` and `東京喰種` are the same script, and only
/// one of them is Chinese.
enum WorkOrigin { japan, china }

class AnimeSummary {
  const AnimeSummary({
    required this.id,
    required this.title,
    required this.sourceTitle,
    this.imageUrl,
    this.thumbnailUrl,
    this.score,
    this.airDate,
    this.summary,
    this.episodes,
    this.popularity,
    this.origin,
  });

  final AnimeSourceId id;
  final String title;
  final String sourceTitle;

  /// The full-size cover: what the hero and the detail page draw.
  final Uri? imageUrl;

  /// The list-size rendition of [imageUrl], when the source publishes one —
  /// Bangumi keeps a ~400px copy beside the full-size cover, and a grid tile
  /// asking for the full-size one downloads several times the pixels it can
  /// show. Null when the source has only one rendition, in which case the
  /// caller falls back to [imageUrl].
  final Uri? thumbnailUrl;

  final double? score;
  final DateTime? airDate;
  final String? summary;

  /// Known episode count for display (`更新至第X话`) and AniList enrichment.
  final int? episodes;

  /// Public follow/popularity counter used for stable schedule ordering.
  final int? popularity;

  /// The country the source files this work under, when it says so.
  ///
  /// A listing does not carry it — the calendar endpoint publishes no
  /// `meta_tags` — so it is filled in by the subject request and is null until
  /// that answers. See [WorkOrigin] for what it is for.
  final WorkOrigin? origin;

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
        other.thumbnailUrl == thumbnailUrl &&
        other.score == score &&
        other.airDate == airDate &&
        other.summary == summary &&
        other.episodes == episodes &&
        other.popularity == popularity &&
        other.origin == origin;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    sourceTitle,
    imageUrl,
    thumbnailUrl,
    score,
    airDate,
    summary,
    episodes,
    popularity,
    origin,
  );
}

final class AnimeDetail extends AnimeSummary {
  const AnimeDetail({
    required super.id,
    required super.title,
    required super.sourceTitle,
    super.imageUrl,
    super.thumbnailUrl,
    super.score,
    super.airDate,
    super.summary,
    super.episodes,
    super.popularity,
    super.origin,
    this.rank,
    this.scoreCount,
    this.format,
    this.tags = const <String>[],
    this.studio,
    this.sourceMaterial,
    this.durationMinutes,
  });

  final int? rank;
  final int? scoreCount;
  final String? format;
  final List<String> tags;

  /// Who animated it, when the source credits a studio for this work.
  final String? studio;

  /// The work it adapts, when it adapts one.
  final String? sourceMaterial;

  /// Length of one episode, when the source publishes it.
  final int? durationMinutes;
}
