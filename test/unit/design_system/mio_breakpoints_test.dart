import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';

void main() {
  group('MioBreakpoints', () {
    test('classifies widths at every boundary', () {
      expect(MioBreakpoints.windowClassFor(599), MioWindowClass.compact);
      expect(MioBreakpoints.windowClassFor(600), MioWindowClass.medium);
      expect(MioBreakpoints.windowClassFor(1023), MioWindowClass.medium);
      expect(MioBreakpoints.windowClassFor(1024), MioWindowClass.expanded);
    });

    test('rejects widths that cannot represent a viewport', () {
      expect(() => MioBreakpoints.windowClassFor(-1), throwsArgumentError);
    });
  });
}
