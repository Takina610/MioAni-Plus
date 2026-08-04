import 'package:mio_ani/src/features/library/domain/library_models.dart';

enum LibraryQueryGroup {
  all,
  watching,
  completed,
  planned,
  paused,
  dropped;

  String get queryValue => name;
  String get label => switch (this) {
    LibraryQueryGroup.all => '全部',
    LibraryQueryGroup.watching => '在看',
    LibraryQueryGroup.completed => '看过',
    LibraryQueryGroup.planned => '想看',
    LibraryQueryGroup.paused => '暂停',
    LibraryQueryGroup.dropped => '弃置',
  };

  static LibraryQueryGroup parse(String? value) =>
      switch (value?.toLowerCase()) {
        'watching' => LibraryQueryGroup.watching,
        'completed' => LibraryQueryGroup.completed,
        'planned' => LibraryQueryGroup.planned,
        'paused' => LibraryQueryGroup.paused,
        'dropped' => LibraryQueryGroup.dropped,
        _ => LibraryQueryGroup.all,
      };
}

enum LibrarySort { updated, title, progress }

final class LibraryQuery {
  const LibraryQuery({
    this.group = LibraryQueryGroup.all,
    this.sort = LibrarySort.updated,
    this.query = '',
    this.descending = true,
  });

  final LibraryQueryGroup group;
  final LibrarySort sort;
  final String query;
  final bool descending;

  LibraryQuery normalized() => LibraryQuery(
    group: group,
    sort: sort,
    query: query.trim().replaceAll(RegExp(r'\s+'), ' '),
    descending: descending,
  );

  Uri applyTo(Uri uri) {
    final normalizedValue = normalized();
    final params = <String, String>{};
    if (normalizedValue.group == LibraryQueryGroup.all) {
      params.remove('group');
    } else {
      params['group'] = normalizedValue.group.queryValue;
    }
    if (normalizedValue.sort == LibrarySort.updated) {
      params.remove('sort');
    } else {
      params['sort'] = normalizedValue.sort.name;
    }
    if (normalizedValue.query.isEmpty) {
      params.remove('q');
    } else {
      params['q'] = normalizedValue.query;
    }
    if (normalizedValue.descending) {
      params.remove('dir');
    } else {
      params['dir'] = 'asc';
    }
    return uri.replace(queryParameters: params);
  }

  static LibraryQuery fromUri(Uri uri) {
    final params = uri.queryParameters;
    final sort = switch (params['sort']) {
      'title' => LibrarySort.title,
      'progress' => LibrarySort.progress,
      _ => LibrarySort.updated,
    };
    return LibraryQuery(
      group: LibraryQueryGroup.parse(params['group']),
      sort: sort,
      query: params['q'] ?? '',
      descending: params['dir'] != 'asc',
    ).normalized();
  }

  @override
  bool operator ==(Object other) =>
      other is LibraryQuery &&
      other.group == group &&
      other.sort == sort &&
      other.query == query &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(group, sort, query, descending);
}

extension LibraryQueryStatusX on LibraryQueryGroup {
  LibraryWatchStatus? get status => switch (this) {
    LibraryQueryGroup.all => null,
    LibraryQueryGroup.watching => LibraryWatchStatus.watching,
    LibraryQueryGroup.completed => LibraryWatchStatus.completed,
    LibraryQueryGroup.planned => LibraryWatchStatus.planned,
    LibraryQueryGroup.paused => LibraryWatchStatus.paused,
    LibraryQueryGroup.dropped => LibraryWatchStatus.dropped,
  };
}
