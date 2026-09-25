import 'dart:collection';
import 'dart:typed_data';

/// The covers this session has already read, held as the very byte lists that
/// were handed to the widgets drawing them.
///
/// The durable store answers from the device's disk, which is fast but not
/// free, and Flutter keys a decoded image by the *identity* of the byte list it
/// was decoded from: reading the same poster back from disk hands over a fresh
/// list, so the tile scrolled away and scrolled back to both re-reads the file
/// and decodes it again. Holding the bytes here means a poster that has been on
/// screen once is given back as the same instance, which paints from the decode
/// the platform cache already holds.
///
/// Both bounds matter: posters run from tens of kilobytes to a few hundred, so
/// [maximumBytes] is what usually binds, and [maximumEntries] only keeps a
/// pathological run of tiny images from growing the map.
///
/// The bytes handed out must be treated as read-only — every caller shares the
/// same list.
final class ImageMemoryCache {
  ImageMemoryCache({
    this.maximumBytes = 16 * 1024 * 1024,
    this.maximumEntries = 256,
  });

  final int maximumBytes;
  final int maximumEntries;

  /// Insertion order is recency: a read moves its entry to the end.
  final LinkedHashMap<Uri, Uint8List> _entries =
      LinkedHashMap<Uri, Uint8List>();
  int _bytes = 0;

  int get byteCount => _bytes;

  int get length => _entries.length;

  /// The bytes held for [uri], or null when it is not a cover this session has
  /// seen. The lookup counts as a use.
  Uint8List? read(Uri uri) {
    final bytes = _entries.remove(uri);
    if (bytes == null) return null;
    _entries[uri] = bytes;
    return bytes;
  }

  /// The bytes held for [uri] without counting as a use, for asking whether a
  /// cover is already on hand.
  Uint8List? peek(Uri uri) => _entries[uri];

  /// Holds [bytes] under [uri]. The list is shared, not copied, so the caller
  /// that stores them and the callers that read them back see one instance.
  void store(Uri uri, Uint8List bytes) {
    if (bytes.isEmpty) return;
    final previous = _entries.remove(uri);
    if (previous != null) _bytes -= previous.length;
    _entries[uri] = bytes;
    _bytes += bytes.length;
    _evict();
  }

  void remove(Uri uri) {
    final bytes = _entries.remove(uri);
    if (bytes != null) _bytes -= bytes.length;
  }

  void clear() {
    _entries.clear();
    _bytes = 0;
  }

  void _evict() {
    // The newest entry is never evicted: one cover larger than the whole budget
    // would otherwise leave the cache empty the moment it was stored.
    while (_entries.length > maximumEntries ||
        (_bytes > maximumBytes && _entries.length > 1)) {
      final oldest = _entries.keys.first;
      _bytes -= _entries.remove(oldest)!.length;
    }
  }
}
