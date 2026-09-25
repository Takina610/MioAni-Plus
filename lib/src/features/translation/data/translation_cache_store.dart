import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:mio_ani/src/core/persistence/catalog_database.dart';

/// Where translations are kept between sessions.
///
/// A translation is worth keeping for two reasons beyond the request it saves:
/// it is the same answer every time, and a page whose title was Japanese
/// yesterday should not go back to being Japanese because the phone is
/// offline today.
abstract interface class TranslationCacheStore {
  /// The translation of [source] into Chinese, or null if there is none.
  Future<String?> read(String source);

  Future<void> write(String source, String translation);
}

/// A cache that lives as long as the app does, for a run with no database
/// behind it — a widget test, mostly.
final class MemoryTranslationCacheStore implements TranslationCacheStore {
  final Map<String, String> _entries = <String, String>{};

  @override
  Future<String?> read(String source) async => _entries[source];

  @override
  Future<void> write(String source, String translation) async {
    _entries[source] = translation;
  }
}

/// The cache the app writes to, in the structured cache it already keeps.
///
/// A translation is a small string keyed by the text it came from, which is the
/// same shape as the catalogue's cached payloads, so it goes in the same table
/// under its own category rather than in a table of its own: the budget and the
/// eviction that already look after the catalogue look after these too, and an
/// old cache full of posters pushes translations out rather than growing
/// without bound.
final class DriftTranslationCacheStore implements TranslationCacheStore {
  const DriftTranslationCacheStore(this.database);

  final MioAniDatabase database;

  static const String _prefix = 'translation:v1:';

  @override
  Future<String?> read(String source) async {
    final row = await database.readCacheEntry(_key(source));
    if (row == null) return null;
    try {
      final decoded = jsonDecode(row.payload);
      if (decoded is! Map<Object?, Object?>) return null;
      final text = decoded['text'];
      return text is String && text.isNotEmpty ? text : null;
    } on FormatException {
      await database.deleteCacheEntry(_key(source));
      return null;
    }
  }

  @override
  Future<void> write(String source, String translation) {
    final payload = jsonEncode(<String, Object?>{'text': translation});
    final now = DateTime.now().toUtc();
    return database.writeCacheEntry(
      StructuredCacheEntriesCompanion.insert(
        cacheKey: _key(source),
        payload: payload,
        fetchedAt: now.millisecondsSinceEpoch,
        staleAt: now.millisecondsSinceEpoch,
        // A translation does not go off: the words it was made from are the
        // ones the source still publishes, and the answer for them cannot
        // change. It leaves the cache when the cache needs the room, not
        // because a clock ran out.
        expiresAt: now.add(const Duration(days: 3650)).millisecondsSinceEpoch,
        category: const Value<String>('translation'),
        byteSize: Value<int>(utf8.encode(payload).length),
        lastAccessedAt: Value<int>(now.millisecondsSinceEpoch),
      ),
    );
  }

  /// The key for [source]: the text itself, hashed.
  ///
  /// Hashed rather than stored, because a synopsis is hundreds of characters
  /// and the key is a primary key on every write; a collision between two
  /// different texts would show one work's translation on another, so the
  /// length is kept beside the hash to make that a practical impossibility
  /// rather than a hope.
  static String _key(String source) {
    final hash = source.codeUnits.fold<int>(0, (value, unit) {
      return ((value * 31) + unit) & 0x7fffffff;
    });
    return '$_prefix${source.length}:$hash';
  }
}
