import 'dart:async';

import 'package:mio_ani/src/features/imports/domain/import_models.dart';

typedef ImportProgressListener = void Function(ImportProgress progress);

final class ImportCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;

  void throwIfCancelled() {
    if (_cancelled) throw const ImportCancelledException();
  }
}

final class ImportCancelledException implements Exception {
  const ImportCancelledException();
  @override
  String toString() => '公开收藏导入已取消';
}

final class ImportStagingSession {
  ImportStagingSession({
    required this.sessionId,
    required this.profile,
    DateTime Function()? clock,
    this.onProgress,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final String sessionId;
  final PublicAccountProfile profile;
  final DateTime Function() _clock;
  final ImportProgressListener? onProgress;
  final List<CollectionPage> _pages = <CollectionPage>[];
  final Map<String, PublicCollectionItem> _items =
      <String, PublicCollectionItem>{};
  int? _declaredTotal;
  bool _complete = false;
  ImportIntegrityStatus _status = ImportIntegrityStatus.collecting;
  Object? _failure;

  List<CollectionPage> get pages => List<CollectionPage>.unmodifiable(_pages);
  List<PublicCollectionItem> get items =>
      List<PublicCollectionItem>.unmodifiable(_items.values);
  int? get declaredTotal => _declaredTotal;
  bool get isComplete => _complete;
  ImportIntegrityStatus get status => _status;
  Object? get failure => _failure;

  void addPage(CollectionPage page) {
    _ensureCollecting();
    if (page.page != _pages.length + 1) {
      fail(
        ImportIntegrityException(
          '分页不连续：期望第 ${_pages.length + 1} 页，收到第 ${page.page} 页。',
        ),
      );
      throw _failure!;
    }
    if (page.declaredTotal != null) {
      if (_declaredTotal != null && _declaredTotal != page.declaredTotal) {
        fail(const ImportIntegrityException('来源声明的总数在分页之间发生变化。'));
        throw _failure!;
      }
      _declaredTotal = page.declaredTotal;
    }
    _pages.add(page);
    for (final item in page.items) {
      _items[item.sourceId] = item;
    }
    onProgress?.call(
      ImportProgress(
        stage: ImportStage.fetchingPages,
        pagesFetched: _pages.length,
        itemsParsed: _items.length,
        declaredTotal: _declaredTotal,
        message: '已读取第 ${page.page} 页公开收藏',
      ),
    );
  }

  ImportSnapshot complete() {
    _ensureCollecting();
    if (_pages.isEmpty) {
      fail(const ImportIntegrityException('尚未读取任何收藏分页。'));
      throw _failure!;
    }
    if (_pages.last.hasNextPage) {
      fail(const ImportIntegrityException('来源仍有下一页，不能提前完成导入。'));
      throw _failure!;
    }
    if (_declaredTotal != null && _declaredTotal != _items.length) {
      fail(
        ImportIntegrityException(
          '来源声明 $_declaredTotal 条，实际去重后 ${_items.length} 条。',
        ),
      );
      throw _failure!;
    }
    _complete = true;
    _status = ImportIntegrityStatus.complete;
    final snapshot = ImportSnapshot(
      sessionId: sessionId,
      profile: profile,
      items: items,
      pagesFetched: _pages.length,
      declaredTotal: _declaredTotal,
      fingerprint: computeImportFingerprint(profile.key, items),
      status: _status,
      createdAt: _clock(),
    );
    onProgress?.call(
      ImportProgress(
        stage: ImportStage.previewing,
        pagesFetched: _pages.length,
        itemsParsed: _items.length,
        declaredTotal: _declaredTotal,
        message: '公开收藏读取完成，正在生成预览',
      ),
    );
    return snapshot;
  }

  void cancel() {
    if (_complete) return;
    _status = ImportIntegrityStatus.cancelled;
    _failure = const ImportCancelledException();
  }

  void fail(Object error) {
    if (_complete) return;
    _status = ImportIntegrityStatus.failed;
    _failure = error;
  }

  ImportSnapshot incompleteSnapshot() => ImportSnapshot(
    sessionId: sessionId,
    profile: profile,
    items: items,
    pagesFetched: _pages.length,
    declaredTotal: _declaredTotal,
    fingerprint: '',
    status: _status == ImportIntegrityStatus.collecting
        ? ImportIntegrityStatus.incomplete
        : _status,
    createdAt: _clock(),
  );

  void _ensureCollecting() {
    if (_status != ImportIntegrityStatus.collecting) {
      throw ImportIntegrityException('暂存会话已结束：$_status');
    }
  }
}

String computeImportFingerprint(
  PublicAccountKey account,
  Iterable<PublicCollectionItem> items,
) {
  final values =
      items
          .map(
            (item) => <String>[
              item.sourceId,
              item.observation.title.trim(),
              ...item.observation.aliases.map((value) => value.trim()),
              item.observation.year?.toString() ?? '',
              item.observation.season?.trim() ?? '',
              item.observation.episodes?.toString() ?? '',
              item.status.name,
              item.watched.toString(),
              item.totalEpisodes?.toString() ?? '',
            ].join('\u001f'),
          )
          .toList()
        ..sort();
  final canonical = <String>[
    account.source.name,
    account.stableUserId,
    ...values,
  ].join('\u001e');
  final hashes = <int>[
    _hash32(canonical, 0x811c9dc5, 0),
    _hash32(canonical, 0x9e3779b9, 0x9e),
    _hash32(canonical, 0x85ebca6b, 0x37),
    _hash32(canonical, 0xc2b2ae35, 0x71),
  ];
  return hashes.map((value) => value.toRadixString(16).padLeft(8, '0')).join();
}

int _hash32(String input, int seed, int salt) {
  var hash = seed;
  for (final codeUnit in input.codeUnits) {
    hash = ((hash ^ (codeUnit + salt)) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

Future<ImportSnapshot> collectPages({
  required ImportStagingSession session,
  required Future<CollectionPage> Function(int page) fetchPage,
  ImportCancellationToken? cancellation,
  int maximumPages = 1000,
}) async {
  final token = cancellation ?? ImportCancellationToken();
  for (var page = 1; page <= maximumPages; page++) {
    token.throwIfCancelled();
    final result = await fetchPage(page);
    token.throwIfCancelled();
    session.addPage(result);
    if (!result.hasNextPage) return session.complete();
  }
  session.fail(const ImportIntegrityException('超过安全分页上限，无法证明收藏完整。'));
  throw session.failure!;
}
