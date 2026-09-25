import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_dto.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_infobox.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

const int _maximumDetailTags = 6;

/// Widths, in pixels, the app draws a Bangumi cover at.
///
/// The originals are huge: a subject's `large` cover is around 1700×2400 and up
/// to a megabyte, which is more than any screen in this app shows. Bangumi's
/// CDN resizes on demand, so the two sizes the app actually paints are asked
/// for by name instead of downloading the original and scaling it down:
///
/// * [_listCoverWidth] for grid tiles and list rows (a three-column phone tile
///   is about 320 physical pixels wide),
/// * [_heroCoverWidth] for the hero card and the detail poster, which are drawn
///   around 900 and 840 physical pixels wide.
///
/// The API's own `common` rendition is *not* either of these: it is a 150×212
/// thumbnail, four times too small for a tile and up to twenty times too small
/// for the hero. So the sizes are derived rather than taken from the payload.
const int _listCoverWidth = 400;
const int _heroCoverWidth = 800;

AnimeSummary mapBangumiSummary(BangumiSubjectDto dto) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(dto.id),
    title: _firstText(<String?>[dto.nameCn, dto.name]) ?? '',
    sourceTitle: _firstText(<String?>[dto.name, dto.nameCn]) ?? '',
    imageUrl: _coverUri(dto.images, _heroCoverWidth),
    thumbnailUrl: _coverUri(dto.images, _listCoverWidth),
    score: dto.rating?.score,
    airDate: _date(dto.airDate ?? dto.date),
    summary: _cleanText(dto.summary),
    episodes: dto.eps ?? dto.totalEpisodes,
    popularity: dto.collection?.doing,
  );
}

/// Maps a full subject. [facts] are the subject's own infobox, which is what
/// names the studio and the adapted work — the summary endpoints do not carry
/// either, so a caller that has no infobox still gets a detail, with those two
/// left unfilled.
AnimeDetail mapBangumiDetail(
  BangumiSubjectDto dto, {
  BangumiSubjectFacts facts = BangumiSubjectFacts.empty,
}) {
  final summary = mapBangumiSummary(dto);
  final tags = dto.tags
      .map((tag) => tag.name.trim())
      .where((name) => name.isNotEmpty)
      .take(_maximumDetailTags)
      .toList(growable: false);
  return AnimeDetail(
    id: summary.id,
    title: summary.title,
    sourceTitle: summary.sourceTitle,
    imageUrl: summary.imageUrl,
    thumbnailUrl: summary.thumbnailUrl,
    score: summary.score,
    airDate: summary.airDate,
    summary: summary.summary,
    episodes: summary.episodes,
    popularity: summary.popularity,
    rank: dto.rank ?? dto.rating?.rank,
    scoreCount: dto.rating?.total,
    format: _firstText(<String?>[dto.platform, ...dto.metaTags]),
    tags: tags,
    origin: _origin(dto.metaTags),
    studio: facts.studio,
    sourceMaterial: facts.sourceMaterial,
    durationMinutes: facts.durationMinutes,
  );
}

/// The country Bangumi files a work under, from its `meta_tags`.
///
/// The tag is the source's own filing and it is always there: of sixty summer
/// subjects sampled, every one carried either `日本` or `中国`. Nothing else in
/// the payload says where a work is from — and a Chinese work and a Japanese
/// one can be written in exactly the same characters, so this is the only
/// honest answer to "is this page in Chinese".
WorkOrigin? _origin(List<String> metaTags) {
  for (final tag in metaTags) {
    switch (tag.trim()) {
      case '日本':
        return WorkOrigin.japan;
      case '中国':
        return WorkOrigin.china;
    }
  }
  return null;
}

/// The cover [images] at [width] pixels wide.
///
/// Most endpoints publish the original alone — the weekly calendar, which is
/// where the home page's poster grid comes from, names no rendition at all —
/// and the ones that do name the small fixed thumbnail rather than the size a
/// screen wants. Both are the same picture as the CDN's `/r/<width>/` resize of
/// the original, so the size the app paints is asked for directly, and a
/// listing that carries no original at all falls back to whatever it does
/// carry.
Uri? _coverUri(BangumiImagesDto? images, int width) {
  if (images == null) return null;
  final largest = _imageUri(images.best);
  if (largest == null) return null;
  if (largest.host != NetworkUriPolicy.bangumiImageHost) return largest;
  final resized = _resizableCover(largest);
  if (resized == null) return largest;
  return resized.replace(path: '/r/$width${resized.path}');
}

/// [uri] as the original the CDN can resize, or null when it is not one.
///
/// Only an original can be resized: a URL that already carries `/r/<width>/`,
/// or that names one of the fixed renditions (`/pic/cover/c/`, `.../m/`, `.../g/`,
/// `.../s/`), is a picture of an already-decided size, and stacking a resize on
/// it would ask for something that does not exist.
Uri? _resizableCover(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length < 3) return null;
  if (segments.first == 'r') return null;
  if (segments.length >= 3 &&
      segments[0] == 'pic' &&
      segments[1] == 'cover' &&
      segments[2] != 'l') {
    return null;
  }
  return uri;
}

Uri? _imageUri(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final upgraded = value.trim().replaceFirst(RegExp(r'^http://'), 'https://');
  final uri = Uri.tryParse(upgraded);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}

String? _firstText(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String? _cleanText(String? value) {
  if (value == null) return null;
  final cleaned = value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
      .replaceAll(RegExp('<[^>]+>'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.isEmpty ? null : cleaned;
}

DateTime? _date(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return DateTime.tryParse(value.trim());
}
