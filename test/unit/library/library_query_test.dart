import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/library/domain/library_query.dart';

void main() {
  test('library query only serializes safe group and sort fields', () {
    final base = Uri.parse('https://example.test/library');
    final query = LibraryQuery(
      group: LibraryQueryGroup.paused,
      sort: LibrarySort.title,
      query: '  银河  ',
      descending: false,
    );
    final uri = query.applyTo(base);
    expect(uri.queryParameters, <String, String>{
      'group': 'paused',
      'sort': 'title',
      'q': '银河',
      'dir': 'asc',
    });
    expect(uri.queryParameters.containsKey('identity'), isFalse);
    expect(uri.queryParameters.containsKey('username'), isFalse);
    expect(LibraryQuery.fromUri(uri), query.normalized());
  });
}
