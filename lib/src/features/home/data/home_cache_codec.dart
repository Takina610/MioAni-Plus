import 'dart:convert';

import 'package:mio_ani/src/features/catalog/data/anime_summary_codec.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

/// JSON codec for the cached home partitions.
final class HomeCacheCodec {
  const HomeCacheCodec({this.summaryCodec = const AnimeSummaryCodec()});

  final AnimeSummaryCodec summaryCodec;

  String encodeSections(HomeCatalogContent sections) {
    return jsonEncode(<String, Object?>{
      'hero': sections.hero.map(summaryCodec.toJson).toList(growable: false),
      'trending': sections.trending
          .map(summaryCodec.toJson)
          .toList(growable: false),
    });
  }

  HomeCatalogContent decodeSections(String payload) {
    final decoded = jsonDecode(payload);
    final map = summaryCodec.objectMap(decoded, 'Home sections cache');
    return HomeCatalogContent(
      hero: _decodeList(map['hero'], 'hero'),
      trending: _decodeList(map['trending'], 'trending'),
    );
  }

  String encodeExplore(HomeExplorePage page) {
    return jsonEncode(<String, Object?>{
      'page': page.page,
      'hasMore': page.hasMore,
      'source': page.source.name,
      'items': page.items.map(summaryCodec.toJson).toList(growable: false),
    });
  }

  HomeExplorePage decodeExplore(String payload) {
    final decoded = jsonDecode(payload);
    final map = summaryCodec.objectMap(decoded, 'Home explore cache');
    final page = map['page'];
    final hasMore = map['hasMore'];
    final source = _source(map['source']);
    if (page is! int || hasMore is! bool || source == null) {
      throw const FormatException(
        'Home explore cache must carry a page number, hasMore and its source',
      );
    }
    return HomeExplorePage(
      items: _decodeList(map['items'], 'items'),
      page: page,
      hasMore: hasMore,
      source: source,
    );
  }

  /// The ranking a cached feed was read from. An unknown name is a record this
  /// build cannot page, which is not a feed to guess about.
  AnimeSource? _source(Object? value) {
    if (value is! String) return null;
    for (final source in AnimeSource.values) {
      if (source.name == value) return source;
    }
    return null;
  }

  List<AnimeSummary> _decodeList(Object? value, String field) {
    if (value is! List<Object?>) {
      throw FormatException('Home cache $field must be a list');
    }
    return value
        .map(
          (item) => summaryCodec.fromJson(
            summaryCodec.objectMap(item, 'Home cache item'),
          ),
        )
        .toList(growable: false);
  }
}
