import 'dart:convert';

import 'package:mio_ani/src/features/catalog/data/anime_summary_codec.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// The stored name of a [WorkOrigin], back as the value it names.
///
/// An unknown or absent name is null rather than a guess: a cache written by a
/// build that did not record this says nothing about where the work is from,
/// and the page falls back to reading the text.
WorkOrigin? _origin(Object? value) {
  return switch (value) {
    'japan' => WorkOrigin.japan,
    'china' => WorkOrigin.china,
    _ => null,
  };
}

final class CatalogCacheCodec {
  const CatalogCacheCodec({this.summaryCodec = const AnimeSummaryCodec()});

  final AnimeSummaryCodec summaryCodec;

  String encodeCatalog(List<AnimeSummary> items) {
    return jsonEncode(items.map(summaryCodec.toJson).toList(growable: false));
  }

  List<AnimeSummary> decodeCatalog(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List<Object?>) {
      throw const FormatException('Catalog cache must be a list');
    }
    return decoded
        .map(
          (item) => summaryCodec.fromJson(
            summaryCodec.objectMap(item, 'Catalog item'),
          ),
        )
        .toList(growable: false);
  }

  String encodeDetail(AnimeDetail detail) {
    return jsonEncode(<String, Object?>{
      ...summaryCodec.toJson(detail),
      'rank': detail.rank,
      'scoreCount': detail.scoreCount,
      'format': detail.format,
      'tags': detail.tags,
      'origin': detail.origin?.name,
      'studio': detail.studio,
      'sourceMaterial': detail.sourceMaterial,
      'durationMinutes': detail.durationMinutes,
    });
  }

  AnimeDetail decodeDetail(String payload) {
    final decoded = jsonDecode(payload);
    final map = summaryCodec.objectMap(decoded, 'Anime detail cache');
    final summary = summaryCodec.fromJson(map);
    final tagsObject = map['tags'];
    final tags = switch (tagsObject) {
      null => const <String>[],
      final List<Object?> values =>
        values
            .map((value) {
              if (value is! String) {
                throw const FormatException('Detail tag must be a string');
              }
              return value;
            })
            .toList(growable: false),
      _ => throw const FormatException('Detail tags must be a list'),
    };
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
      rank: summaryCodec.nullableInt(map['rank']),
      scoreCount: summaryCodec.nullableInt(map['scoreCount']),
      format: summaryCodec.nullableString(map['format']),
      tags: tags,
      origin: _origin(map['origin']),
      studio: summaryCodec.nullableString(map['studio']),
      sourceMaterial: summaryCodec.nullableString(map['sourceMaterial']),
      durationMinutes: summaryCodec.nullableInt(map['durationMinutes']),
    );
  }
}
