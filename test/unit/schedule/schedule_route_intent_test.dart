import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_route_intent.dart';

void main() {
  test('falls back to today and normalizes when the query is absent', () {
    final date = normalizeScheduleDate(
      null,
      now: () => DateTime(2026, 8, 4, 15, 30),
    );
    expect(date, DateTime(2026, 8, 4));
  });

  test('keeps a valid local date and zeroes the time', () {
    final date = normalizeScheduleDate(
      '2026-08-04',
      now: () => DateTime(2026, 8, 1),
    );
    expect(date, DateTime(2026, 8, 4));
  });

  test('rejects malformed and rolled-over values', () {
    for (final invalid in <String?>[
      'garbage',
      '2026-8-04',
      '2026-13-01',
      '2026-02-31',
      '2026-02-30',
      '',
      ' 2026-08-04 ',
    ]) {
      final date = normalizeScheduleDate(
        invalid,
        now: () => DateTime(2026, 8, 4, 9),
      );
      expect(date, DateTime(2026, 8, 4), reason: invalid);
    }
  });
}
