import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// Shared JSON shape for `AnimeSummary` inside structured caches (catalog,
/// schedule and home). Kept as one codec so all three cache layers decode the
/// same fields instead of drifting apart.
final class AnimeSummaryCodec {
  const AnimeSummaryCodec();

  Map<String, Object?> toJson(AnimeSummary item) {
    return <String, Object?>{
      'id': item.id.value,
      'title': item.title,
      'sourceTitle': item.sourceTitle,
      'imageUrl': item.imageUrl?.toString(),
      'score': item.score,
      'airDate': item.airDate?.toIso8601String(),
      'summary': item.summary,
      'episodes': item.episodes,
      'popularity': item.popularity,
    };
  }

  AnimeSummary fromJson(Map<String, Object?> map) {
    final idText = requiredString(map['id'], 'id');
    final id = AnimeSourceId.tryParse(idText);
    if (id == null) throw const FormatException('Invalid cached anime id');
    return AnimeSummary(
      id: id,
      title: requiredString(map['title'], 'title'),
      sourceTitle: nullableString(map['sourceTitle']) ?? '',
      imageUrl: httpsUri(map['imageUrl']),
      score: nullableDouble(map['score']),
      airDate: nullableDate(map['airDate']),
      summary: nullableString(map['summary']),
      episodes: nullableInt(map['episodes']),
      popularity: nullableInt(map['popularity']),
    );
  }

  Map<String, Object?> objectMap(Object? value, String label) {
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

  String requiredString(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing cache field: $field');
    }
    return value;
  }

  String? nullableString(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Expected a string');
    return value;
  }

  int? nullableInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw const FormatException('Expected an integer');
  }

  double? nullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    throw const FormatException('Expected a number');
  }

  DateTime? nullableDate(Object? value) {
    final text = nullableString(value);
    if (text == null) return null;
    final date = DateTime.tryParse(text);
    if (date == null) throw const FormatException('Expected an ISO date');
    return date;
  }

  Uri? httpsUri(Object? value) {
    final text = nullableString(value);
    if (text == null) return null;
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Expected an HTTPS image URI');
    }
    return uri;
  }
}
