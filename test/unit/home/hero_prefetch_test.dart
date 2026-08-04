import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/presentation/hero_prefetch.dart';

void main() {
  test('prefetches only current and next hero images', () {
    final requested = <Uri>[];

    final items = <AnimeSummary>[
      _anime(1, Uri.parse('https://lain.bgm.tv/1.jpg')),
      _anime(2, Uri.parse('https://lain.bgm.tv/2.jpg')),
      _anime(3, Uri.parse('https://lain.bgm.tv/3.jpg')),
    ];
    final prefetcher = HeroImagePrefetcher();

    prefetcher.prefetch(request: requested.add, items: items, current: 0);
    expect(requested, <Uri>[
      Uri.parse('https://lain.bgm.tv/1.jpg'),
      Uri.parse('https://lain.bgm.tv/2.jpg'),
    ]);

    requested.clear();
    prefetcher.prefetch(request: requested.add, items: items, current: 1);
    // Slide 1 is already warm; only the new next slide is requested.
    expect(requested, <Uri>[Uri.parse('https://lain.bgm.tv/3.jpg')]);
  });

  test('never requests slides outside current/next even after a jump', () {
    final requested = <Uri>[];

    final items = <AnimeSummary>[
      _anime(1, Uri.parse('https://lain.bgm.tv/1.jpg')),
      _anime(2, Uri.parse('https://lain.bgm.tv/2.jpg')),
      _anime(3, Uri.parse('https://lain.bgm.tv/3.jpg')),
      _anime(4, Uri.parse('https://lain.bgm.tv/4.jpg')),
    ];
    final prefetcher = HeroImagePrefetcher();

    prefetcher.prefetch(request: requested.add, items: items, current: 2);
    expect(requested, <Uri>[
      Uri.parse('https://lain.bgm.tv/3.jpg'),
      Uri.parse('https://lain.bgm.tv/4.jpg'),
    ]);
  });
}

AnimeSummary _anime(int id, Uri imageUrl) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: '动画$id',
    sourceTitle: '',
    imageUrl: imageUrl,
  );
}
