import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/lcov_coverage.dart';

void main() {
  test('counts unique executable lines and excludes generated Dart files', () {
    const lcov = '''
SF:lib/src/example.dart
DA:1,1
DA:2,0
DA:2,1
DA:3,0
end_of_record
SF:lib/src/example.g.dart
DA:1,0
DA:2,0
end_of_record
''';

    final summary = parseLcov(lcov);

    expect(summary.foundLines, 3);
    expect(summary.hitLines, 2);
    expect(summary.percentage, closeTo(66.67, 0.01));
    expect(summary.sources, ['lib/src/example.dart']);
  });

  test('reports whether the configured line threshold is satisfied', () {
    const summary = CoverageSummary(
      foundLines: 10,
      hitLines: 8,
      sources: ['lib/example.dart'],
    );

    expect(summary.meets(80), isTrue);
    expect(summary.meets(80.01), isFalse);
  });
}
