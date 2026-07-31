@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/image/image_byte_store_web.dart';
import 'package:web/web.dart' as web;

void main() {
  final firstUri = Uri.parse(
    'https://lain.bgm.tv/pic/cover/web.jpg?token=private-value',
  );
  final secondUri = Uri.parse('https://lain.bgm.tv/pic/cover/second.jpg');

  setUp(() async {
    await web.window.caches
        .delete(WebCacheStorageImageByteStore.cacheName)
        .toDart;
  });

  tearDown(() async {
    await web.window.caches
        .delete(WebCacheStorageImageByteStore.cacheName)
        .toDart;
  });

  test(
    'persists bytes across instances without exposing source URLs',
    () async {
      final first = WebCacheStorageImageByteStore();
      await first.write(firstUri, Uint8List.fromList(<int>[1, 2, 3]));

      final second = WebCacheStorageImageByteStore();
      expect(await second.read(firstUri), Uint8List.fromList(<int>[1, 2, 3]));

      final cache = await web.window.caches
          .open(WebCacheStorageImageByteStore.cacheName)
          .toDart;
      final requests = (await cache.keys().toDart).toDart;
      expect(requests, hasLength(1));
      expect(requests.single.url, isNot(contains('private-value')));
      expect(requests.single.url, isNot(contains('lain.bgm.tv')));
    },
  );

  test('delete and clear affect only the MioAni cache namespace', () async {
    final store = WebCacheStorageImageByteStore();
    await store.write(firstUri, Uint8List.fromList(<int>[1]));
    await store.write(secondUri, Uint8List.fromList(<int>[2]));

    await store.delete(firstUri);
    expect(await store.read(firstUri), isNull);
    expect(await store.read(secondUri), Uint8List.fromList(<int>[2]));

    await store.clear();
    expect(await store.read(secondUri), isNull);
    expect(
      await web.window.caches
          .has(WebCacheStorageImageByteStore.cacheName)
          .toDart,
      isFalse,
    );
  });
}
