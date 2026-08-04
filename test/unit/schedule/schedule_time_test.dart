import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';

void main() {
  group('ScheduleTime.tryParse', () {
    test('parses HH:mm with leading zeros', () {
      expect(
        ScheduleTime.tryParse('23:30'),
        ScheduleTime.fromHourMinute(23, 30),
      );
      expect(ScheduleTime.tryParse('09:05'), ScheduleTime.fromHourMinute(9, 5));
    });

    test('parses single-digit hour with colon', () {
      expect(ScheduleTime.tryParse('9:05'), ScheduleTime.fromHourMinute(9, 5));
    });

    test('parses compact digit forms', () {
      expect(
        ScheduleTime.tryParse('2330'),
        ScheduleTime.fromHourMinute(23, 30),
      );
      expect(ScheduleTime.tryParse('930'), ScheduleTime.fromHourMinute(9, 30));
    });

    test('rejects invalid hour and minute ranges', () {
      expect(ScheduleTime.tryParse('24:00'), isNull);
      expect(ScheduleTime.tryParse('23:60'), isNull);
      expect(ScheduleTime.tryParse('2400'), isNull);
      expect(ScheduleTime.tryParse('2360'), isNull);
    });

    test('rejects garbage and null', () {
      expect(ScheduleTime.tryParse(null), isNull);
      expect(ScheduleTime.tryParse(''), isNull);
      expect(ScheduleTime.tryParse('   '), isNull);
      expect(ScheduleTime.tryParse('abc'), isNull);
      expect(ScheduleTime.tryParse('25:99'), isNull);
    });

    test('normalizes to zero-padded text', () {
      expect(ScheduleTime.tryParse('9:05')!.text, '09:05');
      expect(ScheduleTime.tryParse('930')!.text, '09:30');
      expect(ScheduleTime.tryParse('23:30')!.text, '23:30');
    });
  });

  test('compareTo orders by minutes since midnight', () {
    final early = ScheduleTime.fromHourMinute(8, 30);
    final late = ScheduleTime.fromHourMinute(23, 30);
    expect(early.compareTo(late), lessThan(0));
    expect(late.compareTo(early), greaterThan(0));
    expect(early.compareTo(ScheduleTime.fromHourMinute(8, 30)), 0);
  });
}
