import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/home/domain/season_window.dart';

void main() {
  test('resolves the calendar quarter that contains the date', () {
    expect(currentSeasonWindow(DateTime(2026, 1, 15)), (
      start: DateTime(2026, 1, 1),
      end: DateTime(2026, 4, 1),
    ));
    expect(currentSeasonWindow(DateTime(2026, 5, 31)), (
      start: DateTime(2026, 4, 1),
      end: DateTime(2026, 7, 1),
    ));
    expect(currentSeasonWindow(DateTime(2026, 8, 4)), (
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 10, 1),
    ));
    expect(currentSeasonWindow(DateTime(2026, 11, 30)), (
      start: DateTime(2026, 10, 1),
      end: DateTime(2027, 1, 1),
    ));
  });

  test('a window is half-open on both ends', () {
    final now = DateTime(2026, 8, 4);

    expect(isInCurrentSeason(DateTime(2026, 7, 1), now), isTrue);
    expect(isInCurrentSeason(DateTime(2026, 9, 30), now), isTrue);
    expect(isInCurrentSeason(DateTime(2026, 10, 1), now), isFalse);
    expect(isInCurrentSeason(DateTime(2026, 6, 30), now), isFalse);
  });

  test('a show without a premiere date cannot join a season', () {
    expect(isInCurrentSeason(null, DateTime(2026, 8, 4)), isFalse);
  });
}
