import 'dart:js_interop';
import 'dart:typed_data';

import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/core/image/image_storage_key.dart';
import 'package:web/web.dart' as web;

Future<int> loadWebImageCacheCapacityBytes({
  ImageCacheCapacityPolicy policy = const ImageCacheCapacityPolicy(),
}) async {
  try {
    final estimate = await web.window.navigator.storage.estimate().toDart;
    return policy.capacityFor(
      platform: ImageCachePlatform.web,
      quotaBytes: estimate.quota,
      usageBytes: estimate.usage,
    );
  } catch (_) {
    return policy.capacityFor(platform: ImageCachePlatform.web);
  }
}

final class WebCacheStorageImageByteStore implements ImageByteStore {
  static const String cacheName = 'mio_ani-image-bytes-v1';
  static const String _requestPathPrefix = '/__mio_ani_cache__/images/v1';

  @override
  Future<Uint8List?> read(Uri uri) async {
    try {
      final cache = await web.window.caches.open(cacheName).toDart;
      final response = await cache.match(_requestUrl(uri).toJS).toDart;
      if (response == null) return null;
      return Uint8List.fromList((await response.bytes().toDart).toDart);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ImageByteWriteResult?> write(Uri uri, Uint8List bytes) async {
    try {
      final cache = await web.window.caches.open(cacheName).toDart;
      final response = web.Response(Uint8List.fromList(bytes).toJS);
      await cache.put(_requestUrl(uri).toJS, response).toDart;
      return ImageByteWriteResult(
        storageKey: createImageStorageKey(uri),
        backend: ImageCacheBackend.webCache,
      );
    } catch (_) {
      // Cache Storage, browser policy and quota failures are degradable.
      return null;
    }
  }

  @override
  Future<void> delete(Uri uri) async {
    try {
      final cache = await web.window.caches.open(cacheName).toDart;
      await cache.delete(_requestUrl(uri).toJS).toDart;
    } catch (_) {
      // Missing or unavailable Cache Storage is equivalent to a cache miss.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await web.window.caches.delete(cacheName).toDart;
    } catch (_) {
      // Clearing the rebuildable MioAni namespace is best-effort.
    }
  }

  static String _requestUrl(Uri uri) {
    return Uri.base
        .replace(
          path: '$_requestPathPrefix/${createImageStorageKey(uri)}',
          query: null,
          fragment: null,
        )
        .toString();
  }
}
