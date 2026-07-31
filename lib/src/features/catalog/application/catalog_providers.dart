import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:mio_ani/src/core/image/image_byte_store_factory.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/core/persistence/catalog_database.dart';
import 'package:mio_ani/src/features/catalog/data/bangumi_catalog_source.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_repository.dart';
import 'package:mio_ani/src/features/catalog/data/catalog_repository_impl.dart';
import 'package:mio_ani/src/features/catalog/data/drift_catalog_cache_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';

const Duration _networkConnectTimeout = Duration(seconds: 5);
const Duration _networkReceiveTimeout = Duration(seconds: 12);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: NetworkUriPolicy.bangumiBaseUri.toString(),
      connectTimeout: _networkConnectTimeout,
      receiveTimeout: _networkReceiveTimeout,
      followRedirects: false,
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

final requestCoordinatorProvider = Provider<RequestCoordinator>((ref) {
  return RequestCoordinator();
});

final catalogDatabaseProvider = Provider<CatalogDatabase>((ref) {
  final database = CatalogDatabase.defaults();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final catalogCacheStoreProvider = Provider<CatalogCacheStore>((ref) {
  return DriftCatalogCacheStore(database: ref.watch(catalogDatabaseProvider));
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final source = BangumiCatalogSource(
    dio: ref.watch(dioProvider),
    coordinator: ref.watch(requestCoordinatorProvider),
  );
  return CatalogRepositoryImpl(
    source: source,
    cache: ref.watch(catalogCacheStoreProvider),
    now: DateTime.now,
  );
});

final catalogRefreshGenerationProvider = StateProvider<int>((ref) => 0);

final detailRefreshGenerationProvider = StateProvider.autoDispose
    .family<int, AnimeSourceId>((ref, id) => 0);

final catalogStreamProvider =
    StreamProvider<CatalogSnapshot<List<AnimeSummary>>>((ref) {
      final refreshGeneration = ref.watch(catalogRefreshGenerationProvider);
      return ref
          .watch(catalogRepositoryProvider)
          .watchCatalog(forceRefresh: refreshGeneration > 0);
    });

final animeDetailStreamProvider = StreamProvider.autoDispose
    .family<CatalogSnapshot<AnimeDetail>, AnimeSourceId>((ref, id) {
      final refreshGeneration = ref.watch(detailRefreshGenerationProvider(id));
      return ref
          .watch(catalogRepositoryProvider)
          .watchDetail(id, forceRefresh: refreshGeneration > 0);
    });

final imageByteStoreProvider = Provider<ImageByteStore>((ref) {
  return createPlatformImageByteStore();
});

final imagePipelineProvider = Provider<ImagePipeline>((ref) {
  final imageCacheCapacity = loadPlatformImageCacheCapacityBytes();
  return DioImagePipeline(
    dio: ref.watch(dioProvider),
    coordinator: ref.watch(requestCoordinatorProvider),
    byteStore: ref.watch(imageByteStoreProvider),
    metadataStore: ref.watch(catalogDatabaseProvider),
    imageCacheCapacityLoader: () => imageCacheCapacity,
  );
});

final imageBytesProvider = FutureProvider.autoDispose.family<Uint8List, Uri>((
  ref,
  uri,
) {
  return ref.watch(imagePipelineProvider).load(uri);
});
