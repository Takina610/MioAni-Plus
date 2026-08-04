import 'dart:convert';

import 'package:mio_ani/src/features/catalog/data/anime_summary_codec.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

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
    );
  }
}
