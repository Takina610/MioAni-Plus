import 'dart:convert';

import 'package:mio_ani/src/features/catalog/data/anime_summary_codec.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

/// JSON codec for the cached `HomeCatalogContent` (hero/recommended/trending).
final class HomeCacheCodec {
  const HomeCacheCodec({this.summaryCodec = const AnimeSummaryCodec()});

  final AnimeSummaryCodec summaryCodec;

  String encodeSections(HomeCatalogContent sections) {
    return jsonEncode(<String, Object?>{
      'hero': sections.hero.map(summaryCodec.toJson).toList(growable: false),
      'recommended': sections.recommended
          .map(summaryCodec.toJson)
          .toList(growable: false),
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
      recommended: _decodeList(map['recommended'], 'recommended'),
      trending: _decodeList(map['trending'], 'trending'),
    );
  }

  List<AnimeSummary> _decodeList(Object? value, String field) {
    if (value is! List<Object?>) {
      throw FormatException('Home sections $field must be a list');
    }
    return value
        .map(
          (item) => summaryCodec.fromJson(
            summaryCodec.objectMap(item, 'Home section item'),
          ),
        )
        .toList(growable: false);
  }
}
