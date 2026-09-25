import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/data/anilist_dto.dart';

/// Maps one AniList media entry onto the shared summary every AniList-backed
/// list reads, so the schedule donors and the home season lineup agree on how a
/// title, its cover and its score are presented.
///
/// The title shown is the entry's own native one — Japanese for essentially
/// every anime AniList carries — with the romanized and English forms behind
/// it. AniList publishes `romaji` first, but a transliteration is not the
/// title anyone reads: it is the fallback, not the display.
///
/// AniList reports `averageScore` on a 0-100 scale while MioAni keeps the
/// 0-10 the rest of the catalogue uses.
///
/// Its cover is taken at `large` and no [AnimeSummary.thumbnailUrl] is offered:
/// AniList's other rendition is `medium`, which is smaller than the tiles it
/// would be drawn into, so there is no saving to take — unlike Bangumi, whose
/// `common` is exactly the size a list shows.
AnimeSummary anilistMediaSummary(AniListMediaDto dto) {
  final title = dto.title;
  final display = title?.native ?? title?.romaji ?? title?.english ?? '';
  final source = title?.romaji ?? title?.english ?? '';
  return AnimeSummary(
    id: AnimeSourceId.fromAniListId(dto.id),
    title: display,
    sourceTitle: source == display ? '' : source,
    imageUrl: anilistCoverUri(dto.coverImage?.large),
    score: dto.averageScore == null ? null : dto.averageScore! / 10,
    episodes: dto.episodes,
    popularity: dto.popularity,
  );
}

/// Cover art is only usable over HTTPS: anything else is dropped here rather
/// than handed to the image pipeline.
Uri? anilistCoverUri(String? value) {
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}
