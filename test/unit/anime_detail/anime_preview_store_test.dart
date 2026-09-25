import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_preview_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

void main() {
  AnimeSummary anime(int id, {String title = '动画'}) {
    return AnimeSummary(
      id: AnimeSourceId.fromBangumiId(id),
      title: title,
      sourceTitle: '',
    );
  }

  test('hands back what a list last showed for an id', () {
    final store = AnimePreviewStore();

    expect(store.lookup('bgm-1'), isNull);

    store.remember(anime(1, title: '第一次'));
    store.remember(anime(1, title: '第二次'));

    expect(store.lookup('bgm-1')?.title, '第二次');
    expect(store.length, 1);
  });

  test('a long session of taps does not grow without bound', () {
    final store = AnimePreviewStore(maximumEntries: 2);

    store.remember(anime(1));
    store.remember(anime(2));
    store.remember(anime(3));

    expect(store.lookup('bgm-1'), isNull);
    expect(store.lookup('bgm-2'), isNotNull);
    expect(store.lookup('bgm-3'), isNotNull);
    expect(store.length, 2);
  });

  test('forget drops a single id', () {
    final store = AnimePreviewStore()..remember(anime(1));

    store.forget('bgm-1');

    expect(store.lookup('bgm-1'), isNull);
  });
}
