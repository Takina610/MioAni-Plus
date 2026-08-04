import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

abstract interface class DiscoverSource {
  AnimeSource get source;

  Future<DiscoverPageResult> fetchPage(
    DiscoverPageRequest request, {
    bool forceNewGeneration = false,
  });

  Future<DiscoverFilterCatalog> fetchFilterCatalog({
    bool forceNewGeneration = false,
  });
}
