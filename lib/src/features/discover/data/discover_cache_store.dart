import 'package:mio_ani/src/features/discover/domain/discover_query.dart';

final class DiscoverCacheRecord {
  const DiscoverCacheRecord({
    required this.value,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
  });

  final DiscoverPageResult value;
  final DateTime fetchedAt;
  final DateTime staleAt;
  final DateTime expiresAt;
}

abstract interface class DiscoverCacheStore {
  Future<DiscoverCacheRecord?> read(String key);
  Future<void> write(String key, DiscoverCacheRecord record);
  Future<void> delete(String key);
}

final class MemoryDiscoverCacheStore implements DiscoverCacheStore {
  final Map<String, DiscoverCacheRecord> _records =
      <String, DiscoverCacheRecord>{};

  @override
  Future<DiscoverCacheRecord?> read(String key) async => _records[key];

  @override
  Future<void> write(String key, DiscoverCacheRecord record) async {
    _records[key] = record;
  }

  @override
  Future<void> delete(String key) async {
    _records.remove(key);
  }
}
