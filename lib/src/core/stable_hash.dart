import 'dart:convert';

const int _mask32 = 0xffffffff;

String createStableHash128(String value) {
  final bytes = utf8.encode(value);
  return <int>[
    _jenkins32(bytes, 0x811c9dc5),
    _jenkins32(bytes, 0x9747b28c),
    _jenkins32(bytes, 0x85ebca6b),
    _jenkins32(bytes, 0xc2b2ae35),
  ].map(_hex32).join();
}

int _jenkins32(List<int> bytes, int seed) {
  var hash = seed;
  for (final byte in bytes) {
    hash = (hash + byte) & _mask32;
    hash = (hash + (hash << 10)) & _mask32;
    hash ^= hash >>> 6;
  }
  hash = (hash + (hash << 3)) & _mask32;
  hash ^= hash >>> 11;
  hash = (hash + (hash << 15)) & _mask32;
  return hash & _mask32;
}

String _hex32(int value) {
  return value.toRadixString(16).padLeft(8, '0');
}
