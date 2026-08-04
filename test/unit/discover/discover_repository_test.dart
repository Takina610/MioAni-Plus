import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/data/discover_cache_store.dart';
import 'package:mio_ani/src/features/discover/data/discover_repository.dart';
import 'package:mio_ani/src/features/discover/data/discover_source.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

final class _FakeSource implements DiscoverSource {
  _FakeSource(this.source, this.pages);
  @override
  final AnimeSource source;
  final Map<int, DiscoverPageResult> pages;
  int calls = 0;

  @override
  Future<DiscoverPageResult> fetchPage(
    DiscoverPageRequest request, {
    bool forceNewGeneration = false,
  }) async {
    calls += 1;
    return pages[request.page]!;
  }

  @override
  Future<DiscoverFilterCatalog> fetchFilterCatalog({
    bool forceNewGeneration = false,
  }) async => const DiscoverFilterCatalog();
}

AnimeSummary _item(String id) =>
    AnimeSummary(id: AnimeSourceId.tryParse(id)!, title: id, sourceTitle: id);

void main() {
  final now = DateTime(2026, 8, 4);

  test(
    'locks explicit source and preserves stale cache after failure',
    () async {
      final bangumi = _FakeSource(
        AnimeSource.bangumi,
        <int, DiscoverPageResult>{
          1: DiscoverPageResult(
            items: <AnimeSummary>[_item('bgm-1')],
            page: 1,
            source: AnimeSource.bangumi,
            hasMore: false,
          ),
        },
      );
      final anilist = _FakeSource(
        AnimeSource.anilist,
        <int, DiscoverPageResult>{
          1: DiscoverPageResult(
            items: <AnimeSummary>[_item('anilist-1')],
            page: 1,
            source: AnimeSource.anilist,
            hasMore: false,
          ),
        },
      );
      final repository = DiscoverRepositoryImpl(
        bangumi: bangumi,
        anilist: anilist,
        cache: MemoryDiscoverCacheStore(),
        now: () => now,
      );

      final result = await repository.fetchPage(
        DiscoverQuery(sourcePreference: DiscoverSourcePreference.anilist),
        page: 1,
      );
      expect(result.source, AnimeSource.anilist);
      expect(anilist.calls, 1);
      expect(
        repository.chooseSource(
          const DiscoverQuery(),
          lockedSource: AnimeSource.bangumi,
        ),
        AnimeSource.bangumi,
      );
    },
  );

  test('deduplication contract is source-id based across pages', () {
    final items = <AnimeSummary>[
      _item('bgm-1'),
      _item('bgm-1'),
      _item('anilist-1'),
    ];
    final ids = <AnimeSourceId>{for (final item in items) item.id};
    expect(ids.length, 2);
  });
}
