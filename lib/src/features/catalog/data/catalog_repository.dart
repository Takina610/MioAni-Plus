import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';

abstract interface class CatalogRepository {
  Stream<CatalogSnapshot<List<AnimeSummary>>> watchCatalog({
    bool forceRefresh = false,
  });

  Stream<CatalogSnapshot<AnimeDetail>> watchDetail(
    AnimeSourceId id, {
    bool forceRefresh = false,
  });
}
