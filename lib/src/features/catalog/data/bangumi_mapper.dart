import 'package:mio_ani/src/features/catalog/data/bangumi_dto.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

const int _maximumDetailTags = 6;

AnimeSummary mapBangumiSummary(BangumiSubjectDto dto) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(dto.id),
    title: _firstText(<String?>[dto.nameCn, dto.name]) ?? '',
    sourceTitle: _firstText(<String?>[dto.name, dto.nameCn]) ?? '',
    imageUrl: _imageUri(dto.images?.large ?? dto.images?.common),
    score: dto.rating?.score,
    airDate: _date(dto.airDate ?? dto.date),
    summary: _cleanText(dto.summary),
    episodes: dto.eps ?? dto.totalEpisodes,
    popularity: dto.collection?.doing,
  );
}

AnimeDetail mapBangumiDetail(BangumiSubjectDto dto) {
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
    score: summary.score,
    airDate: summary.airDate,
    summary: summary.summary,
    episodes: summary.episodes,
    popularity: summary.popularity,
    rank: dto.rank ?? dto.rating?.rank,
    scoreCount: dto.rating?.total,
    format: _firstText(<String?>[dto.platform, ...dto.metaTags]),
    tags: tags,
  );
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

Uri? _imageUri(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final upgraded = value.trim().replaceFirst(RegExp(r'^http://'), 'https://');
  final uri = Uri.tryParse(upgraded);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri;
}
