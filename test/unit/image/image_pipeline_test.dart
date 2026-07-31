import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/image_byte_store_factory.dart';
import 'package:mio_ani/src/core/image/image_byte_store_native.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

void main() {
  test('image cache capacity follows the platform and Web quota contract', () {
    const policy = ImageCacheCapacityPolicy();

    expect(policy.capacityFor(platform: ImageCachePlatform.android), 268435456);
    expect(policy.capacityFor(platform: ImageCachePlatform.windows), 536870912);
    expect(
      policy.capacityFor(
        platform: ImageCachePlatform.web,
        quotaBytes: 629145600,
        usageBytes: 104857600,
      ),
      104857600,
    );
    expect(
      policy.capacityFor(
        platform: ImageCachePlatform.web,
        quotaBytes: 2147483648,
        usageBytes: 0,
      ),
      268435456,
    );
    expect(policy.capacityFor(platform: ImageCachePlatform.web), 134217728);
  });

  test('web direct image fallback only accepts allowed offline images', () {
    final allowedUri = Uri.parse(
      'https://lain.bgm.tv/pic/cover/web-direct.jpg',
    );

    expect(
      shouldUseWebDirectImageFallback(
        isWeb: true,
        uri: allowedUri,
        error: const OfflineFailure(),
      ),
      isTrue,
    );
    expect(
      shouldUseWebDirectImageFallback(
        isWeb: false,
        uri: allowedUri,
        error: const OfflineFailure(),
      ),
      isFalse,
    );
    expect(
      shouldUseWebDirectImageFallback(
        isWeb: true,
        uri: Uri.parse('https://example.com/untrusted.jpg'),
        error: const OfflineFailure(),
      ),
      isFalse,
    );
    expect(
      shouldUseWebDirectImageFallback(
        isWeb: true,
        uri: allowedUri,
        error: const NotFoundFailure(),
      ),
      isFalse,
    );
    expect(
      shouldUseWebDirectImageFallback(
        isWeb: true,
        uri: allowedUri,
        error: const BrowserPolicyFailure(),
      ),
      isFalse,
    );
  });

  test('validates image hosts and caches successful bytes in memory', () async {
    final adapter = _BytesAdapter(<int>[1, 2, 3]);
    final dio = Dio()..httpClientAdapter = adapter;
    final pipeline = DioImagePipeline(
      dio: dio,
      coordinator: RequestCoordinator(),
    );
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/test.jpg');

    expect(await pipeline.load(uri), Uint8List.fromList(<int>[1, 2, 3]));
    expect(await pipeline.load(uri), Uint8List.fromList(<int>[1, 2, 3]));
    expect(adapter.calls, 1);

    expect(
      () => pipeline.load(Uri.parse('https://example.com/test.jpg')),
      throwsA(isA<BrowserPolicyFailure>()),
    );
    expect(adapter.calls, 1);
  });

  test('maps empty image responses to an application failure', () async {
    final dio = Dio()..httpClientAdapter = _BytesAdapter(const <int>[]);
    final pipeline = DioImagePipeline(
      dio: dio,
      coordinator: RequestCoordinator(),
    );

    await expectLater(
      pipeline.load(Uri.parse('https://lain.bgm.tv/pic/cover/empty.jpg')),
      throwsA(isA<InvalidPayloadFailure>()),
    );
  });

  test('returns fresh durable bytes and touches their access time', () async {
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/fresh.jpg');
    final now = DateTime.utc(2026, 7, 31, 8);
    final byteStore = _PersistentByteStore(
      cachedBytes: Uint8List.fromList(<int>[7, 8]),
    );
    final metadataStore = _RecordingImageCacheMetadataStore(
      initialEntries: <ImageCacheMetadata>[
        ImageCacheMetadata(
          uri: uri,
          storageKey: 'fresh-key',
          backend: ImageCacheBackend.nativeFile,
          byteSize: 2,
          etag: null,
          lastModified: null,
          fetchedAt: DateTime.utc(2026, 7, 1),
          staleAt: DateTime.utc(2026, 8, 1),
          expiresAt: DateTime.utc(2026, 8, 1),
          lastAccessedAt: DateTime.utc(2026, 7, 1),
        ),
      ],
    );
    final adapter = _BytesAdapter(<int>[9]);
    final pipeline = DioImagePipeline(
      dio: Dio()..httpClientAdapter = adapter,
      coordinator: RequestCoordinator(),
      byteStore: byteStore,
      metadataStore: metadataStore,
      now: () => now,
    );

    expect(await pipeline.load(uri), Uint8List.fromList(<int>[7, 8]));
    expect(adapter.calls, 0);
    expect(metadataStore.touchedAt[uri], now);
  });

  test(
    'repairs only the durable image whose byte size is inconsistent',
    () async {
      final uri = Uri.parse('https://lain.bgm.tv/pic/cover/damaged.jpg');
      final otherUri = Uri.parse('https://lain.bgm.tv/pic/cover/kept.jpg');
      final now = DateTime.utc(2026, 7, 31, 8);
      ImageCacheMetadata metadata(Uri value, String key) => ImageCacheMetadata(
        uri: value,
        storageKey: key,
        backend: ImageCacheBackend.nativeFile,
        byteSize: 2,
        etag: null,
        lastModified: null,
        fetchedAt: DateTime.utc(2026, 7, 1),
        staleAt: DateTime.utc(2026, 8, 1),
        expiresAt: DateTime.utc(2026, 8, 1),
        lastAccessedAt: DateTime.utc(2026, 7, 1),
      );

      final byteStore = _PersistentByteStore(
        cachedBytes: Uint8List.fromList(<int>[7]),
      );
      final metadataStore = _RecordingImageCacheMetadataStore(
        initialEntries: <ImageCacheMetadata>[
          metadata(uri, 'damaged-key'),
          metadata(otherUri, 'kept-key'),
        ],
      );
      final adapter = _BytesAdapter(<int>[9, 9, 9]);
      final pipeline = DioImagePipeline(
        dio: Dio()..httpClientAdapter = adapter,
        coordinator: RequestCoordinator(),
        byteStore: byteStore,
        metadataStore: metadataStore,
        now: () => now,
      );

      expect(await pipeline.load(uri), Uint8List.fromList(<int>[9, 9, 9]));
      expect(adapter.calls, 1);
      expect(byteStore.deletedUris, <Uri>[uri]);
      expect(metadataStore.deletedUris, <Uri>[uri]);
      expect(metadataStore.storedEntries, contains(otherUri));
    },
  );

  test('revalidates stale durable bytes and reuses them after 304', () async {
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/stale.jpg');
    final now = DateTime.utc(2026, 7, 31, 8);
    final staleBytes = Uint8List.fromList(<int>[7, 8]);
    final byteStore = _PersistentByteStore(cachedBytes: staleBytes);
    final metadataStore = _RecordingImageCacheMetadataStore(
      initialEntries: <ImageCacheMetadata>[
        ImageCacheMetadata(
          uri: uri,
          storageKey: 'stale-key',
          backend: ImageCacheBackend.nativeFile,
          byteSize: staleBytes.length,
          etag: '"image-v1"',
          lastModified: 'Wed, 30 Jul 2026 10:00:00 GMT',
          fetchedAt: DateTime.utc(2026, 6, 1),
          staleAt: DateTime.utc(2026, 7, 1),
          expiresAt: DateTime.utc(2026, 7, 1),
          lastAccessedAt: DateTime.utc(2026, 6, 1),
        ),
      ],
    );
    final adapter = _BytesAdapter(const <int>[], statusCode: 304);
    final pipeline = DioImagePipeline(
      dio: Dio()..httpClientAdapter = adapter,
      coordinator: RequestCoordinator(),
      byteStore: byteStore,
      metadataStore: metadataStore,
      now: () => now,
    );

    expect(await pipeline.load(uri), staleBytes);
    expect(adapter.lastRequestOptions!.headers['If-None-Match'], '"image-v1"');
    expect(
      adapter.lastRequestOptions!.headers['If-Modified-Since'],
      'Wed, 30 Jul 2026 10:00:00 GMT',
    );
    expect(byteStore.writeCalls, 0);
    expect(metadataStore.entries, hasLength(1));
    final renewed = metadataStore.entries.single;
    expect(renewed.storageKey, 'stale-key');
    expect(renewed.backend, ImageCacheBackend.nativeFile);
    expect(renewed.byteSize, staleBytes.length);
    expect(renewed.etag, '"image-v1"');
    expect(renewed.lastModified, 'Wed, 30 Jul 2026 10:00:00 GMT');
    expect(renewed.fetchedAt, now);
    expect(renewed.staleAt, DateTime.utc(2026, 8, 30, 8));
    expect(renewed.expiresAt, DateTime.utc(2026, 8, 30, 8));
    expect(renewed.lastAccessedAt, now);
  });

  test(
    'uses complete stale durable bytes only when revalidation is offline',
    () async {
      final uri = Uri.parse('https://lain.bgm.tv/pic/cover/offline-stale.jpg');
      final staleBytes = Uint8List.fromList(<int>[7, 8]);
      final byteStore = _PersistentByteStore(cachedBytes: staleBytes);
      final metadataStore = _RecordingImageCacheMetadataStore(
        initialEntries: <ImageCacheMetadata>[
          ImageCacheMetadata(
            uri: uri,
            storageKey: 'offline-stale-key',
            backend: ImageCacheBackend.nativeFile,
            byteSize: staleBytes.length,
            etag: '"image-v1"',
            lastModified: null,
            fetchedAt: DateTime.utc(2026, 6, 1),
            staleAt: DateTime.utc(2026, 7, 1),
            expiresAt: DateTime.utc(2026, 7, 1),
            lastAccessedAt: DateTime.utc(2026, 6, 1),
          ),
        ],
      );
      final pipeline = DioImagePipeline(
        dio: Dio()..httpClientAdapter = _ConnectionErrorAdapter(),
        coordinator: RequestCoordinator(),
        byteStore: byteStore,
        metadataStore: metadataStore,
        now: () => DateTime.utc(2026, 7, 31, 8),
      );

      expect(await pipeline.load(uri), staleBytes);
      expect(byteStore.writeCalls, 0);
      expect(metadataStore.entries, isEmpty);

      final upstreamPipeline = DioImagePipeline(
        dio: Dio()
          ..httpClientAdapter = _BytesAdapter(const <int>[], statusCode: 503),
        coordinator: RequestCoordinator(),
        byteStore: byteStore,
        metadataStore: metadataStore,
        now: () => DateTime.utc(2026, 7, 31, 8),
      );
      await expectLater(
        upstreamPipeline.load(uri),
        throwsA(isA<UpstreamFailure>()),
      );
    },
  );

  test('records durable metadata after a successful image write', () async {
    final byteStore = _PersistentByteStore();
    final metadataStore = _RecordingImageCacheMetadataStore();
    final pipeline = DioImagePipeline(
      dio: Dio()
        ..httpClientAdapter = _BytesAdapter(
          <int>[1, 2, 3],
          headers: <String, List<String>>{
            'etag': <String>['"image-v1"'],
            'last-modified': <String>['Wed, 30 Jul 2026 10:00:00 GMT'],
          },
        ),
      coordinator: RequestCoordinator(),
      byteStore: byteStore,
      metadataStore: metadataStore,
      now: () => DateTime.utc(2026, 7, 31, 8),
    );
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/metadata.jpg');

    await pipeline.load(uri);

    expect(metadataStore.entries, hasLength(1));
    final entry = metadataStore.entries.single;
    expect(entry.uri, uri);
    expect(entry.storageKey, 'durable-key');
    expect(entry.backend, ImageCacheBackend.nativeFile);
    expect(entry.byteSize, 3);
    expect(entry.etag, '"image-v1"');
    expect(entry.lastModified, 'Wed, 30 Jul 2026 10:00:00 GMT');
    expect(entry.fetchedAt, DateTime.utc(2026, 7, 31, 8));
    expect(entry.staleAt, DateTime.utc(2026, 8, 30, 8));
    expect(entry.expiresAt, DateTime.utc(2026, 8, 30, 8));
    expect(entry.lastAccessedAt, DateTime.utc(2026, 7, 31, 8));
  });

  test('deletes durable bytes selected by image budget enforcement', () async {
    final evictedUri = Uri.parse('https://lain.bgm.tv/pic/cover/evicted.jpg');
    final byteStore = _PersistentByteStore();
    final metadataStore = _RecordingImageCacheMetadataStore(
      evictionEntries: <ImageCacheMetadata>[
        ImageCacheMetadata(
          uri: evictedUri,
          storageKey: 'evicted-key',
          backend: ImageCacheBackend.nativeFile,
          byteSize: 40,
          etag: null,
          lastModified: null,
          fetchedAt: DateTime.utc(2026, 7, 1),
          staleAt: DateTime.utc(2026, 7, 30),
          expiresAt: DateTime.utc(2026, 7, 30),
          lastAccessedAt: DateTime.utc(2026, 7, 1),
        ),
      ],
    );
    final pipeline = DioImagePipeline(
      dio: Dio()..httpClientAdapter = _BytesAdapter(<int>[1, 2, 3]),
      coordinator: RequestCoordinator(),
      byteStore: byteStore,
      metadataStore: metadataStore,
      imageCacheCapacityLoader: () async => 100,
      now: () => DateTime.utc(2026, 7, 31, 8),
    );

    await pipeline.load(
      Uri.parse('https://lain.bgm.tv/pic/cover/new-image.jpg'),
    );

    expect(metadataStore.enforcedMaxBytes, 100);
    expect(byteStore.deletedUris, <Uri>[evictedUri]);
  });

  test('reuses an injected byte store across pipeline instances', () async {
    final store = MemoryImageByteStore();
    final firstAdapter = _BytesAdapter(<int>[4, 5, 6]);
    final first = DioImagePipeline(
      dio: Dio()..httpClientAdapter = firstAdapter,
      coordinator: RequestCoordinator(),
      byteStore: store,
    );
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/persisted.jpg');

    expect(await first.load(uri), Uint8List.fromList(<int>[4, 5, 6]));

    final secondAdapter = _BytesAdapter(<int>[9]);
    final second = DioImagePipeline(
      dio: Dio()..httpClientAdapter = secondAdapter,
      coordinator: RequestCoordinator(),
      byteStore: store,
    );
    expect(await second.load(uri), Uint8List.fromList(<int>[4, 5, 6]));
    expect(firstAdapter.calls, 1);
    expect(secondAdapter.calls, 0);
  });

  test('memory byte store copies bytes and can clear its namespace', () async {
    final store = MemoryImageByteStore();
    final uri = Uri.parse('https://lain.bgm.tv/pic/cover/copy.jpg');
    final source = Uint8List.fromList(<int>[1, 2, 3]);

    await store.write(uri, source);
    source[0] = 9;
    final firstRead = await store.read(uri);
    expect(firstRead, Uint8List.fromList(<int>[1, 2, 3]));

    firstRead![1] = 8;
    expect(await store.read(uri), Uint8List.fromList(<int>[1, 2, 3]));

    await store.clear();
    expect(await store.read(uri), isNull);
  });

  test('platform factory selects the native file store on the Dart VM', () {
    expect(createPlatformImageByteStore(), isA<NativeFileImageByteStore>());
  });

  test('platform factory reports the Windows image cache capacity', () async {
    expect(await loadPlatformImageCacheCapacityBytes(), 536870912);
  });

  group('native file byte store', () {
    late Directory cacheRoot;

    setUp(() async {
      cacheRoot = await Directory.systemTemp.createTemp(
        'mio_ani_image_store_test_',
      );
    });

    tearDown(() async {
      if (await cacheRoot.exists()) {
        await cacheRoot.delete(recursive: true);
      }
    });

    test('persists and atomically replaces bytes across instances', () async {
      final uri = Uri.parse(
        'https://lain.bgm.tv/pic/cover/native.jpg?token=private-value',
      );
      final first = NativeFileImageByteStore(
        cacheDirectoryLoader: () async => cacheRoot,
      );

      await first.write(uri, Uint8List.fromList(<int>[1, 2, 3]));
      final second = NativeFileImageByteStore(
        cacheDirectoryLoader: () async => cacheRoot,
      );
      expect(await second.read(uri), Uint8List.fromList(<int>[1, 2, 3]));

      await second.write(uri, Uint8List.fromList(<int>[4, 5]));
      expect(await first.read(uri), Uint8List.fromList(<int>[4, 5]));

      final namespace = Directory(
        '${cacheRoot.path}${Platform.pathSeparator}'
        'mio_ani${Platform.pathSeparator}image_cache_v1',
      );
      final names = await namespace
          .list()
          .map((entity) => entity.uri.pathSegments.last)
          .toList();
      expect(names, hasLength(1));
      expect(names.single, matches(RegExp(r'^[0-9a-f]{32}\.bin$')));
      expect(names.single, isNot(contains('private-value')));
    });

    test('delete and clear stay inside the MioAni namespace', () async {
      final firstUri = Uri.parse('https://lain.bgm.tv/pic/cover/first.jpg');
      final secondUri = Uri.parse('https://lain.bgm.tv/pic/cover/second.jpg');
      final sibling = File(
        '${cacheRoot.path}${Platform.pathSeparator}keep.txt',
      );
      await sibling.writeAsString('user-owned');
      final store = NativeFileImageByteStore(
        cacheDirectoryLoader: () async => cacheRoot,
      );

      await store.write(firstUri, Uint8List.fromList(<int>[1]));
      await store.write(secondUri, Uint8List.fromList(<int>[2]));
      await store.delete(firstUri);
      expect(await store.read(firstUri), isNull);
      expect(await store.read(secondUri), Uint8List.fromList(<int>[2]));

      await store.clear();
      expect(await store.read(secondUri), isNull);
      expect(await sibling.readAsString(), 'user-owned');
    });

    test('unavailable cache directories degrade to cache misses', () async {
      final store = NativeFileImageByteStore(
        cacheDirectoryLoader: () async => throw Exception('unavailable'),
      );
      final uri = Uri.parse('https://lain.bgm.tv/pic/cover/fallback.jpg');

      expect(await store.read(uri), isNull);
      await expectLater(
        store.write(uri, Uint8List.fromList(<int>[1])),
        completes,
      );
      await expectLater(store.delete(uri), completes);
      await expectLater(store.clear(), completes);
    });
  });
}

final class _BytesAdapter implements HttpClientAdapter {
  _BytesAdapter(
    this.bytes, {
    this.statusCode = 200,
    this.headers = const <String, List<String>>{},
  });

  final List<int> bytes;
  final int statusCode;
  final Map<String, List<String>> headers;
  int calls = 0;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    lastRequestOptions = options;
    return ResponseBody.fromBytes(bytes, statusCode, headers: headers);
  }

  @override
  void close({bool force = false}) {}
}

final class _ConnectionErrorAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _PersistentByteStore implements ImageByteStore {
  _PersistentByteStore({this.cachedBytes});

  final Uint8List? cachedBytes;
  final List<Uri> deletedUris = <Uri>[];
  int writeCalls = 0;

  @override
  Future<void> clear() async {}

  @override
  Future<void> delete(Uri uri) async {
    deletedUris.add(uri);
  }

  @override
  Future<Uint8List?> read(Uri uri) async => cachedBytes;

  @override
  Future<ImageByteWriteResult?> write(Uri uri, Uint8List bytes) async {
    writeCalls += 1;
    return const ImageByteWriteResult(
      storageKey: 'durable-key',
      backend: ImageCacheBackend.nativeFile,
    );
  }
}

final class _RecordingImageCacheMetadataStore
    implements ImageCacheMetadataStore {
  _RecordingImageCacheMetadataStore({
    List<ImageCacheMetadata> initialEntries = const <ImageCacheMetadata>[],
    this.evictionEntries = const <ImageCacheMetadata>[],
  }) : storedEntries = <Uri, ImageCacheMetadata>{
         for (final entry in initialEntries) entry.uri: entry,
       };

  final List<ImageCacheMetadata> entries = <ImageCacheMetadata>[];
  final Map<Uri, ImageCacheMetadata> storedEntries;
  final List<ImageCacheMetadata> evictionEntries;
  final Map<Uri, DateTime> touchedAt = <Uri, DateTime>{};
  final List<Uri> deletedUris = <Uri>[];
  int? enforcedMaxBytes;

  @override
  Future<ImageCacheMetadata?> readImageMetadata(Uri uri) async {
    return storedEntries[uri];
  }

  @override
  Future<void> touchImageMetadata(Uri uri, DateTime accessedAt) async {
    touchedAt[uri] = accessedAt;
  }

  @override
  Future<void> removeImageMetadata(Uri uri) async {
    deletedUris.add(uri);
    storedEntries.remove(uri);
  }

  @override
  Future<List<ImageCacheMetadata>> enforceImageCacheBudget({
    required int maxBytes,
    required DateTime now,
  }) async {
    enforcedMaxBytes = maxBytes;
    return evictionEntries;
  }

  @override
  Future<void> upsert(ImageCacheMetadata entry) async {
    entries.add(entry);
    storedEntries[entry.uri] = entry;
  }
}
