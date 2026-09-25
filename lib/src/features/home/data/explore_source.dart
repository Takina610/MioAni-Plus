import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';

/// Fetch boundary for a paged, source-wide ranking: the home explore feed.
///
/// Each source answers with the page it was asked for, says whether the
/// ranking continues behind it, and names the [source] the ranking belongs to —
/// the repository needs that to keep a feed paging within one list, and to know
/// when a second ranking may take over. How many pages the home page is willing
/// to walk is a cache and presentation policy and lives in the repository, not
/// here.
abstract interface class ExploreAnimeSource {
  /// The data source whose ranking this is.
  AnimeSource get source;

  /// [page] is one-based, and a page is the source's own page: `pageSize` is
  /// what the source accepts as one slice, so that consecutive page numbers
  /// line up against the ranking without skipping entries.
  Future<HomeExplorePage> fetchPage(
    int page, {
    bool forceNewGeneration = false,
  });
}
