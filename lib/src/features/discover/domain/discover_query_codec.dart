import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

final class DiscoverQueryCodec {
  const DiscoverQueryCodec();

  DiscoverQuery parse(Uri uri) {
    final query = uri.queryParameters;
    final genres = (query['genres'] ?? '')
        .split(',')
        .map(Uri.decodeComponent)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final score = _parseScoreRange(query['score']);
    return DiscoverQuery(
      keyword: query['q'] ?? '',
      genres: genres,
      year: _parseYear(query['year']),
      season: DiscoverSeason.tryParse(query['season']),
      airStatus:
          DiscoverAirStatus.tryParse(query['status']) ?? DiscoverAirStatus.all,
      scoreMin: score.$1,
      scoreMax: score.$2,
      sort: DiscoverSort.tryParse(query['sort']) ?? DiscoverSort.relevance,
      format: DiscoverFormat.tryParse(query['format']) ?? DiscoverFormat.all,
      origin: _nullable(query['origin']),
      sourcePreference:
          DiscoverSourcePreference.tryParse(query['source']) ??
          DiscoverSourcePreference.auto,
    ).normalized();
  }

  Uri apply(Uri uri, DiscoverQuery value) {
    final query = <String, String>{
      ...uri.queryParameters,
      ...toParameters(value),
    };
    return uri.replace(queryParameters: query);
  }

  Map<String, String> toParameters(DiscoverQuery value) {
    final query = <String, String>{};
    final normalized = value.normalized();
    if (normalized.keyword.isNotEmpty) {
      query['q'] = normalized.keyword;
    }
    if (normalized.genres.isNotEmpty) {
      query['genres'] = normalized.genres.map(Uri.encodeComponent).join(',');
    }
    if (normalized.year != null) {
      query['year'] = normalized.year.toString();
    }
    if (normalized.season != null) {
      query['season'] = normalized.season!.queryValue;
    }
    if (normalized.airStatus != DiscoverAirStatus.all) {
      query['status'] = normalized.airStatus.queryValue;
    }
    if (normalized.scoreMin != null || normalized.scoreMax != null) {
      query['score'] =
          '${normalized.scoreMin?.toStringAsFixed(1) ?? ''}-${normalized.scoreMax?.toStringAsFixed(1) ?? ''}';
    }
    if (normalized.sort != DiscoverSort.relevance) {
      query['sort'] = normalized.sort.queryValue;
    }
    if (normalized.format != DiscoverFormat.all) {
      query['format'] = normalized.format.queryValue;
    }
    if (normalized.origin != null) {
      query['origin'] = normalized.origin!;
    }
    if (normalized.sourcePreference != DiscoverSourcePreference.auto) {
      query['source'] = normalized.sourcePreference.queryValue;
    }
    return query;
  }

  Uri normalizeUri(Uri uri) {
    final value = parse(uri);
    return uri.replace(queryParameters: toParameters(value));
  }

  static int? _parseYear(String? value) {
    final year = int.tryParse(value ?? '');
    return year != null && year >= 1900 && year <= 2100 ? year : null;
  }

  static (double?, double?) _parseScoreRange(String? value) {
    if (value == null) return (null, null);
    final separator = value.indexOf('-', 1);
    if (separator < 0) return (null, null);
    return (
      double.tryParse(value.substring(0, separator)),
      double.tryParse(value.substring(separator + 1)),
    );
  }

  static String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
