import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/image/image_memory_cache.dart';

void main() {
  final poster = Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/1.jpg');

  Uint8List bytes(int length, {int fill = 1}) {
    return Uint8List.fromList(List<int>.filled(length, fill));
  }

  test('hands back the very list it was given', () {
    final cache = ImageMemoryCache();
    final stored = bytes(4);

    cache.store(poster, stored);

    // Identity is the point: Flutter keys a decoded image by the byte list, so
    // the same list is what lets a re-shown poster paint from the decode it
    // already has.
    expect(identical(cache.read(poster), stored), isTrue);
    expect(identical(cache.read(poster), cache.read(poster)), isTrue);
  });

  test('a miss reads as nothing rather than as an empty cover', () {
    final cache = ImageMemoryCache();

    expect(cache.read(poster), isNull);
    expect(cache.peek(poster), isNull);

    cache.store(poster, Uint8List(0));
    expect(cache.read(poster), isNull);
  });

  test('keeps the newest covers and drops the oldest past its entry bound', () {
    final cache = ImageMemoryCache(maximumEntries: 2);
    final first = Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/1.jpg');
    final second = Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/2.jpg');
    final third = Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/3.jpg');

    cache.store(first, bytes(2));
    cache.store(second, bytes(2));
    // Reading the older cover is a use, so the one evicted is the one neither
    // stored nor read most recently.
    cache.read(first);
    cache.store(third, bytes(2));

    expect(cache.read(first), isNotNull);
    expect(cache.read(third), isNotNull);
    expect(cache.read(second), isNull);
    expect(cache.length, 2);
  });

  test('a cover larger than the whole budget is still held', () {
    final cache = ImageMemoryCache(maximumBytes: 8);

    cache.store(poster, bytes(64));
    expect(cache.read(poster), isNotNull);

    final other = Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/2.jpg');
    cache.store(other, bytes(64));

    // The newest is never evicted to satisfy a budget it alone overruns: an
    // empty cache would only mean reading it from the device again.
    expect(cache.read(other), isNotNull);
    expect(cache.read(poster), isNull);
    expect(cache.byteCount, 64);
  });

  test('drops entries past its byte budget, newest last', () {
    final cache = ImageMemoryCache(maximumBytes: 10);
    final second = Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/2.jpg');

    cache.store(poster, bytes(6));
    cache.store(second, bytes(6));

    expect(cache.byteCount, 6);
    expect(cache.read(second), isNotNull);
    expect(cache.read(poster), isNull);
  });

  test('forget and clear leave nothing behind', () {
    final cache = ImageMemoryCache()..store(poster, bytes(3));

    cache.remove(poster);
    expect(cache.read(poster), isNull);
    expect(cache.byteCount, 0);

    cache.store(poster, bytes(3));
    cache.clear();
    expect(cache.read(poster), isNull);
    expect(cache.byteCount, 0);
  });
}
