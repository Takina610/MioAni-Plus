import 'dart:convert';

import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';

String encodeImportItems(Iterable<PublicCollectionItem> items) => jsonEncode(
  items
      .map((item) {
        return <String, Object?>{
          'sourceId': item.sourceId,
          'title': item.observation.title,
          'aliases': item.observation.aliases,
          'year': item.observation.year,
          'season': item.observation.season,
          'episodes': item.observation.episodes,
          'imageUrl': item.observation.imageUrl?.toString(),
          'status': item.status.name,
          'watched': item.watched,
          'totalEpisodes': item.totalEpisodes,
        };
      })
      .toList(growable: false),
);

List<PublicCollectionItem> decodeImportItems(String value) {
  final raw = jsonDecode(value);
  if (raw is! List<Object?>) return const <PublicCollectionItem>[];
  final result = <PublicCollectionItem>[];
  for (final item in raw) {
    if (item is! Map<Object?, Object?>) continue;
    final map = item.map((key, value) => MapEntry(key.toString(), value));
    final sourceId = AnimeSourceId.tryParse(map['sourceId']?.toString() ?? '');
    if (sourceId == null) continue;
    final status = LibraryWatchStatus.values.firstWhere(
      (candidate) => candidate.name == map['status'],
      orElse: () => LibraryWatchStatus.planned,
    );
    final aliases = (map['aliases'] is List<Object?>)
        ? (map['aliases'] as List<Object?>).whereType<String>().toList(
            growable: false,
          )
        : const <String>[];
    result.add(
      PublicCollectionItem(
        observation: SourceObservation(
          sourceId: sourceId,
          title: map['title'] is String ? map['title'] as String : '',
          aliases: aliases,
          year: _int(map['year']),
          season: map['season'] is String ? map['season'] as String : null,
          episodes: _int(map['episodes']),
          imageUrl: _uri(map['imageUrl']),
        ),
        status: status,
        watched: _int(map['watched']) ?? 0,
        totalEpisodes: _int(map['totalEpisodes']),
      ),
    );
  }
  return List<PublicCollectionItem>.unmodifiable(result);
}

int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');

Uri? _uri(Object? value) {
  final uri = value is String ? Uri.tryParse(value) : null;
  return uri != null && uri.hasScheme ? uri : null;
}
