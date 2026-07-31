import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';

void main() {
  test('accepts only canonical positive Bangumi anime identifiers', () {
    final id = AnimeSourceId.tryParse('bgm-2');

    expect(id, isNotNull);
    expect(id!.rawId, 2);
    expect(id.value, 'bgm-2');

    for (final invalid in <String>[
      '2',
      'bgm-0',
      'bgm--1',
      'bgm-01',
      'anilist-2',
    ]) {
      expect(AnimeSourceId.tryParse(invalid), isNull, reason: invalid);
    }
  });
}
