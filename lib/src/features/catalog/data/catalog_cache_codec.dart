import 'dart:convert';

import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

final class CatalogCacheCodec {
  const CatalogCacheCodec();

  String encodeCatalog(List<AnimeSummary> items) {
    return jsonEncode(items.map(_summaryToJson).toList(growable: false));
  }

  List<AnimeSummary> decodeCatalog(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List<Object?>) {
      throw const FormatException('Catalog cache must be a list');
    }
    return decoded.map(_summaryFromObject).toList(growable: false);
  }

  String encodeDetail(AnimeDetail detail) {
    return jsonEncode(<String, Object?>{
      ..._summaryToJson(detail),
      'episodes': detail.episodes,
      'rank': detail.rank,
      'scoreCount': detail.scoreCount,
      'format': detail.format,
      'tags': detail.tags,
    });
  }

  AnimeDetail decodeDetail(String payload) {
    final decoded = jsonDecode(payload);
    final map = _objectMap(decoded, 'Anime detail cache');
    final summary = _summaryFromMap(map);
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
      episodes: _nullableInt(map['episodes']),
      rank: _nullableInt(map['rank']),
      scoreCount: _nullableInt(map['scoreCount']),
      format: _nullableString(map['format']),
      tags: tags,
    );
  }

  Map<String, Object?> _summaryToJson(AnimeSummary item) {
    return <String, Object?>{
      'id': item.id.value,
      'title': item.title,
      'sourceTitle': item.sourceTitle,
      'imageUrl': item.imageUrl?.toString(),
      'score': item.score,
      'airDate': item.airDate?.toIso8601String(),
      'summary': item.summary,
    };
  }

  AnimeSummary _summaryFromObject(Object? value) {
    return _summaryFromMap(_objectMap(value, 'Catalog item'));
  }

  AnimeSummary _summaryFromMap(Map<String, Object?> map) {
    final idText = _requiredString(map['id'], 'id');
    final id = AnimeSourceId.tryParse(idText);
    if (id == null) throw const FormatException('Invalid cached anime id');
    return AnimeSummary(
      id: id,
      title: _requiredString(map['title'], 'title'),
      sourceTitle: _requiredString(map['sourceTitle'], 'sourceTitle'),
      imageUrl: _httpsUri(map['imageUrl']),
      score: _nullableDouble(map['score']),
      airDate: _nullableDate(map['airDate']),
      summary: _nullableString(map['summary']),
    );
  }

  Map<String, Object?> _objectMap(Object? value, String label) {
    if (value is! Map<Object?, Object?>) {
      throw FormatException('$label must be an object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        throw FormatException('$label contains a non-string key');
      }
      result[key] = entry.value;
    }
    return result;
  }

  String _requiredString(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing cache field: $field');
    }
    return value;
  }

  String? _nullableString(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Expected a string');
    return value;
  }

  int? _nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Expected an integer');
  }

  double? _nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw const FormatException('Expected a number');
  }

  DateTime? _nullableDate(Object? value) {
    final text = _nullableString(value);
    if (text == null) return null;
    final date = DateTime.tryParse(text);
    if (date == null) throw const FormatException('Expected an ISO date');
    return date;
  }

  Uri? _httpsUri(Object? value) {
    final text = _nullableString(value);
    if (text == null) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Expected an HTTPS image URI');
    }
    return uri;
  }
}
