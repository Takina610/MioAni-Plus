import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

abstract interface class CatalogSource {
  Future<List<AnimeSummary>> fetchCatalog({bool forceNewGeneration = false});

  Future<AnimeDetail> fetchDetail(
    AnimeSourceId id, {
    bool forceNewGeneration = false,
  });
}
