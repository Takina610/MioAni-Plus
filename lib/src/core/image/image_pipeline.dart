import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/image_memory_cache.dart';
import 'package:mio_ani/src/core/network/dio_failure_mapper.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';

enum ImageCachePlatform { android, windows, web, unsupported }

enum ImageCacheBackend {
  nativeFile('native_file'),
  webCache('web_cache');

  const ImageCacheBackend(this.storageValue);

  final String storageValue;

  static ImageCacheBackend fromStorageValue(String value) {
    return switch (value) {
      'native_file' => ImageCacheBackend.nativeFile,
      'web_cache' => ImageCacheBackend.webCache,
      _ => throw ArgumentError.value(value, 'value', 'unknown image backend'),
    };
  }
}

final class ImageByteWriteResult {
  const ImageByteWriteResult({required this.storageKey, required this.backend});

  final String storageKey;
  final ImageCacheBackend backend;
}

final class ImageCacheMetadata {
  const ImageCacheMetadata({
    required this.uri,
    required this.storageKey,
    required this.backend,
    required this.byteSize,
    required this.etag,
    required this.lastModified,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
    required this.lastAccessedAt,
  });

  final Uri uri;
  final String storageKey;
  final ImageCacheBackend backend;
  final int byteSize;
  final String? etag;
  final String? lastModified;
  final DateTime fetchedAt;
  final DateTime staleAt;
  final DateTime expiresAt;
  final DateTime lastAccessedAt;
}

abstract interface class ImageCacheMetadataStore {
  Future<ImageCacheMetadata?> readImageMetadata(Uri uri);

  Future<void> touchImageMetadata(Uri uri, DateTime accessedAt);

  Future<void> removeImageMetadata(Uri uri);

  Future<List<ImageCacheMetadata>> enforceImageCacheBudget({
    required int maxBytes,
    required DateTime now,
  });

  Future<void> upsert(ImageCacheMetadata entry);
}

final class ImageCacheCapacityPolicy {
  const ImageCacheCapacityPolicy();

  static const int mebibyte = 1024 * 1024;
  static const int androidCapacityBytes = 256 * mebibyte;
  static const int windowsCapacityBytes = 512 * mebibyte;
  static const int maximumWebCapacityBytes = 256 * mebibyte;
  static const int fallbackWebCapacityBytes = 128 * mebibyte;

  int capacityFor({
    required ImageCachePlatform platform,
    int? quotaBytes,
    int? usageBytes,
  }) {
    return switch (platform) {
      ImageCachePlatform.android => androidCapacityBytes,
      ImageCachePlatform.windows => windowsCapacityBytes,
      ImageCachePlatform.web => _webCapacity(
        quotaBytes: quotaBytes,
        usageBytes: usageBytes,
      ),
      ImageCachePlatform.unsupported => fallbackWebCapacityBytes,
    };
  }

  int _webCapacity({required int? quotaBytes, required int? usageBytes}) {
    if (quotaBytes == null ||
        usageBytes == null ||
        quotaBytes <= 0 ||
        usageBytes < 0) {
      return fallbackWebCapacityBytes;
    }

    final availableBytes = quotaBytes - usageBytes;
    if (availableBytes <= 0) return 0;
    final proportionalCapacity = availableBytes ~/ 5;
    return proportionalCapacity < maximumWebCapacityBytes
        ? proportionalCapacity
        : maximumWebCapacityBytes;
  }
}

abstract interface class ImagePipeline {
  Future<Uint8List> load(Uri uri);
}

abstract interface class ImageByteStore {
  Future<Uint8List?> read(Uri uri);

  Future<ImageByteWriteResult?> write(Uri uri, Uint8List bytes);

  Future<void> delete(Uri uri);

  Future<void> clear();
}

final class MemoryImageByteStore implements ImageByteStore {
  final Map<Uri, Uint8List> _entries = <Uri, Uint8List>{};

  @override
  Future<Uint8List?> read(Uri uri) async {
    final bytes = _entries[uri];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<ImageByteWriteResult?> write(Uri uri, Uint8List bytes) async {
    _entries[uri] = Uint8List.fromList(bytes);
    return null;
  }

  @override
  Future<void> delete(Uri uri) async {
    _entries.remove(uri);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}

final class DioImagePipeline implements ImagePipeline {
  DioImagePipeline({
    required this.dio,
    required this.coordinator,
    ImageByteStore? byteStore,
    ImageMemoryCache? memoryCache,
    this.metadataStore,
    this.imageCacheCapacityLoader,
    DateTime Function()? now,
    this.freshness = const Duration(days: 30),
    this.uriPolicy = const NetworkUriPolicy(),
    this.requestPolicy = _imageRequestPolicy,
  }) : byteStore = byteStore ?? MemoryImageByteStore(),
       memoryCache = memoryCache ?? ImageMemoryCache(),
       now = now ?? _utcNow;

  final Dio dio;
  final RequestCoordinator coordinator;
  final ImageByteStore byteStore;

  /// Covers already read this session, in front of [byteStore] and the network.
  /// Share one across pipelines to keep it alive across rebuilds; the store
  /// itself is what a screen reads from to paint a cover without waiting.
  final ImageMemoryCache memoryCache;

  final ImageCacheMetadataStore? metadataStore;
  final Future<int> Function()? imageCacheCapacityLoader;
  final DateTime Function() now;
  final Duration freshness;
  final NetworkUriPolicy uriPolicy;

  /// What one cover is allowed: see [_imageRequestPolicy].
  final RequestPolicy requestPolicy;

  static DateTime _utcNow() => DateTime.now().toUtc();

  /// How long a cover gets, end to end, before the grid moves on without it.
  static const RequestPolicy _imageRequestPolicy = RequestPolicy(
    deadline: Duration(seconds: 12),
    retryDelays: <Duration>[Duration(milliseconds: 400)],
  );

  /// How long one attempt at a cover may sit on the socket.
  static const Duration _imageReceiveTimeout = Duration(seconds: 8);

  /// How stale a recorded access time is allowed to get before reading a cover
  /// writes a new one. An hour is far finer than eviction needs — a cover read
  /// this hour is not the one to drop when the cache is full — and it is coarse
  /// enough that a screenful of posters costs no writes at all after the first
  /// time it is seen in that hour.
  static const Duration _accessTimeGranularity = Duration(hours: 1);

  Future<void> _enforceImageCacheBudget(DateTime at) async {
    final metadata = metadataStore;
    final capacityLoader = imageCacheCapacityLoader;
    if (metadata == null || capacityLoader == null) return;
    try {
      final capacity = await capacityLoader();
      final evicted = await metadata.enforceImageCacheBudget(
        maxBytes: capacity,
        now: at,
      );
      for (final entry in evicted) {
        await byteStore.delete(entry.uri);
      }
    } on Exception {
      // Image maintenance is best-effort and cannot fail image display.
    }
  }

  @override
  Future<Uint8List> load(Uri uri) async {
    final imageSource = uriPolicy.resolveImageSource(uri);
    // A cover this session has already drawn is handed back as the list the
    // platform decoded from, so a tile scrolled back to paints without a disk
    // read, a metadata query or a decode.
    final held = memoryCache.read(uri);
    if (held != null) return held;
    final metadata = metadataStore;
    ImageCacheMetadata? staleMetadata;
    Uint8List? staleBytes;
    if (metadata == null) {
      final cached = await byteStore.read(uri);
      if (cached != null && cached.isNotEmpty) {
        memoryCache.store(uri, cached);
        return cached;
      }
      if (cached != null) await byteStore.delete(uri);
    } else {
      ImageCacheMetadata? entry;
      try {
        entry = await metadata.readImageMetadata(uri);
      } on Exception {
        // Metadata failures degrade to the network path.
      }
      final accessedAt = now().toUtc();
      if (entry != null) {
        final cached = await byteStore.read(uri);
        final isValid =
            cached != null &&
            cached.isNotEmpty &&
            cached.length == entry.byteSize;
        if (isValid) {
          if (accessedAt.isBefore(entry.staleAt)) {
            // What the touch is for is eviction: the cache drops whatever was
            // read longest ago, and it needs to know this cover was read now.
            // It does not need to know that to the second. Writing only when
            // the recorded time has drifted by [_accessTimeGranularity] keeps
            // the ordering eviction depends on while sparing a write per cover:
            // a poster grid asks for two dozen covers at once, and two dozen
            // SQLite writes is not a thing to do behind a screen that is trying
            // to paint.
            if (accessedAt.difference(entry.lastAccessedAt) >=
                _accessTimeGranularity) {
              try {
                await metadata.touchImageMetadata(uri, accessedAt);
              } on Exception {
                // Access-time maintenance is best-effort.
              }
            }
            memoryCache.store(uri, cached);
            return cached;
          }
          staleMetadata = entry;
          staleBytes = cached;
        } else {
          await byteStore.delete(uri);
          try {
            await metadata.removeImageMetadata(uri);
          } on Exception {
            // A failed repair must not block the network path.
          }
        }
      }
    }
    try {
      return await coordinator.execute<Uint8List>(
        source: imageSource,
        key: 'GET:$uri',
        retryEligible: true,
        // A cover is one file in a screenful of them, and the reader is looking
        // at the other ones while it comes. Holding its slot in the image pool
        // for the API's full deadline is what makes a grid crawl on a network
        // that has gone slow: one stalled host would keep every cover behind it
        // waiting. A cover is therefore given a shorter deadline and one quick
        // retry, and a stale copy is preferred to a long wait.
        policy: requestPolicy,
        operation: () async {
          try {
            final conditionalHeaders = <String, String>{};
            final etag = staleMetadata?.etag;
            if (etag != null) conditionalHeaders['If-None-Match'] = etag;
            final lastModified = staleMetadata?.lastModified;
            if (lastModified != null) {
              conditionalHeaders['If-Modified-Since'] = lastModified;
            }
            final response = await dio.getUri<List<int>>(
              uri,
              options: Options(
                responseType: ResponseType.bytes,
                headers: conditionalHeaders,
                receiveTimeout: _imageReceiveTimeout,
                validateStatus: (status) =>
                    status != null &&
                    ((status >= 200 && status < 300) || status == 304),
              ),
            );
            if (response.statusCode == 304) {
              final reusableMetadata = staleMetadata;
              final reusableBytes = staleBytes;
              if (reusableMetadata == null || reusableBytes == null) {
                throw const InvalidPayloadFailure();
              }
              final fetchedAt = now().toUtc();
              final staleAt = fetchedAt.add(freshness);
              try {
                await metadataStore?.upsert(
                  ImageCacheMetadata(
                    uri: uri,
                    storageKey: reusableMetadata.storageKey,
                    backend: reusableMetadata.backend,
                    byteSize: reusableMetadata.byteSize,
                    etag:
                        response.headers.value('etag') ?? reusableMetadata.etag,
                    lastModified:
                        response.headers.value('last-modified') ??
                        reusableMetadata.lastModified,
                    fetchedAt: fetchedAt,
                    staleAt: staleAt,
                    expiresAt: staleAt,
                    lastAccessedAt: fetchedAt,
                  ),
                );
                await _enforceImageCacheBudget(fetchedAt);
              } on Exception {
                // Rebuildable metadata failures must not fail image display.
              }
              memoryCache.store(uri, reusableBytes);
              return reusableBytes;
            }
            final bytes = response.data;
            if (bytes == null || bytes.isEmpty) {
              throw const InvalidPayloadFailure();
            }
            final result = Uint8List.fromList(bytes);
            memoryCache.store(uri, result);
            final writeResult = await byteStore.write(uri, result);
            if (writeResult != null && metadataStore != null) {
              final fetchedAt = now().toUtc();
              final staleAt = fetchedAt.add(freshness);
              try {
                await metadataStore!.upsert(
                  ImageCacheMetadata(
                    uri: uri,
                    storageKey: writeResult.storageKey,
                    backend: writeResult.backend,
                    byteSize: result.length,
                    etag: response.headers.value('etag'),
                    lastModified: response.headers.value('last-modified'),
                    fetchedAt: fetchedAt,
                    staleAt: staleAt,
                    expiresAt: staleAt,
                    lastAccessedAt: fetchedAt,
                  ),
                );
                await _enforceImageCacheBudget(fetchedAt);
              } on Exception {
                // Rebuildable metadata failures must not fail image display.
              }
            }
            return result;
          } on DioException catch (error) {
            throw mapDioFailure(error);
          }
        },
      );
    } on OfflineFailure {
      final fallback = staleBytes;
      if (fallback != null) return fallback;
      rethrow;
    } on TimeoutFailure {
      // Too slow is the same answer as unreachable for a cover that has a copy
      // on the device: the reader would rather see yesterday's poster than an
      // empty tile while the request sits in its deadline.
      final fallback = staleBytes;
      if (fallback != null) return fallback;
      rethrow;
    }
  }
}
