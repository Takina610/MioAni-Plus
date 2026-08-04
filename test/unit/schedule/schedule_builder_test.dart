import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

AnimeSummary _anime(int id, String title, {int? popularity}) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: title,
    popularity: popularity,
  );
}

ScheduleSourceItem _item(
  AnimeSummary anime,
  ScheduleWeekday weekday, {
  ScheduleTime? airTime,
}) {
  return ScheduleSourceItem(anime: anime, weekday: weekday, airTime: airTime);
}

void main() {
  group('buildWeekSchedule', () {
    test('produces seven days Monday-first with isToday flags', () {
      final now = DateTime(2026, 8, 4); // Tuesday.
      final days = buildWeekSchedule(const [], now);

      expect(days, hasLength(7));
      expect(days.map((day) => day.weekday), ScheduleWeekday.values);
      expect(days.first.weekday, ScheduleWeekday.monday);
      expect(days.last.weekday, ScheduleWeekday.sunday);
      expect(
        days.where((day) => day.isToday).single.weekday,
        ScheduleWeekday.tuesday,
      );
    });

    test('deduplicates by source id across days (first wins)', () {
      final anime = _anime(2, '初音岛');
      final days = buildWeekSchedule([
        _item(anime, ScheduleWeekday.monday),
        _item(
          anime,
          ScheduleWeekday.wednesday,
          airTime: ScheduleTime.tryParse('23:30'),
        ),
      ], DateTime(2026, 8, 4));

      final allItems = days.expand((day) => day.items);
      expect(allItems.where((item) => item.anime.id == anime.id), hasLength(1));
      expect(
        allItems.singleWhere((item) => item.anime.id == anime.id).weekday,
        ScheduleWeekday.monday,
      );
    });

    test('sorts timed items ascending and untimed after timed', () {
      final late = _anime(1, '晚场', popularity: 5);
      final early = _anime(2, '早场', popularity: 5);
      final untimed = _anime(3, '待定', popularity: 100);

      final days = buildWeekSchedule([
        _item(untimed, ScheduleWeekday.monday),
        _item(
          late,
          ScheduleWeekday.monday,
          airTime: ScheduleTime.tryParse('23:30'),
        ),
        _item(
          early,
          ScheduleWeekday.monday,
          airTime: ScheduleTime.tryParse('08:30'),
        ),
      ], DateTime(2026, 8, 4));

      final items = days.first.items;
      expect(items.map((item) => item.anime.id.rawId), [2, 1, 3]);
      expect(items.first.timed, isTrue);
      expect(items.last.timed, isFalse);
    });

    test('untimed items sort by popularity desc then title', () {
      final lessPopular = _anime(1, '阿卡', popularity: 10);
      final morePopular = _anime(2, '甲', popularity: 20);
      final samePopularity = _anime(3, '乙', popularity: 20);

      final days = buildWeekSchedule([
        _item(lessPopular, ScheduleWeekday.tuesday),
        _item(morePopular, ScheduleWeekday.tuesday),
        _item(samePopularity, ScheduleWeekday.tuesday),
      ], DateTime(2026, 8, 4));

      final ids = days
          .firstWhere((day) => day.weekday == ScheduleWeekday.tuesday)
          .items
          .map((item) => item.anime.id.rawId);
      // Tie break is stable code-unit title ordering (no locale collation):
      // 乙 (U+4E59) sorts before 甲 (U+7532).
      expect(ids, [3, 2, 1]);
    });

    test('unknown weekday input never leaks into the template', () {
      final days = buildWeekSchedule(const [], DateTime(2026, 8, 4));
      expect(scheduleHasContent(days), isFalse);
      expect(days.every((day) => day.items.isEmpty), isTrue);
    });
  });

  group('flattenRecentSchedule', () {
    test('deduplicates across days and applies stable ordering', () {
      final shared = _anime(9, '跨天动画', popularity: 50);
      final days = buildWeekSchedule([
        _item(_anime(1, '甲', popularity: 10), ScheduleWeekday.monday),
        _item(
          shared,
          ScheduleWeekday.tuesday,
          airTime: ScheduleTime.tryParse('22:00'),
        ),
        _item(shared, ScheduleWeekday.saturday),
      ], DateTime(2026, 8, 4));

      final flat = flattenRecentSchedule(days, 10);
      expect(flat.map((item) => item.anime.id.rawId).toSet(), {1, 9});
      expect(flat.first.anime.id.rawId, 9); // timed before untimed
    });

    test('honors the limit', () {
      final days = buildWeekSchedule([
        for (var i = 1; i <= 20; i += 1)
          _item(_anime(i, '动画$i'), ScheduleWeekday.monday),
      ], DateTime(2026, 8, 4));

      expect(flattenRecentSchedule(days, 14), hasLength(14));
      expect(flattenRecentSchedule(days, 0), isEmpty);
    });
  });

  group('date helpers', () {
    test('startOfLocalDay zeroes the time of day', () {
      final value = DateTime(2026, 8, 4, 23, 59, 59);
      expect(startOfLocalDay(value), DateTime(2026, 8, 4));
    });

    test('addLocalDays crosses month and DST boundaries by local calendar', () {
      expect(addLocalDays(DateTime(2026, 8, 31), 1), DateTime(2026, 9, 1));
      // March 1 minus one day lands on Feb 28 in a non-leap year.
      expect(addLocalDays(DateTime(2026, 3, 1), -1), DateTime(2026, 2, 28));
    });

    test('sliceScheduleWindow returns consecutive local midnights', () {
      final window = sliceScheduleWindow(DateTime(2026, 8, 4, 15, 30), 3);
      expect(window, [
        DateTime(2026, 8, 4),
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 6),
      ]);
      expect(sliceScheduleWindow(DateTime(2026, 8, 4), 0), isEmpty);
    });

    test('mondayOfWeek anchors any local date to Monday midnight', () {
      // 2026-08-04 is a Tuesday; its week starts Monday 2026-08-03.
      expect(mondayOfWeek(DateTime(2026, 8, 4, 23, 59)), DateTime(2026, 8, 3));
      // Sunday belongs to the same week as the preceding Monday.
      expect(mondayOfWeek(DateTime(2026, 8, 9)), DateTime(2026, 8, 3));
      // Monday anchors to itself.
      expect(mondayOfWeek(DateTime(2026, 8, 3)), DateTime(2026, 8, 3));
      // January boundary: 2026-01-01 is a Thursday → week starts 2025-12-29.
      expect(mondayOfWeek(DateTime(2026, 1, 1)), DateTime(2025, 12, 29));
    });

    test('weekdayForDate follows the local calendar', () {
      // 2026-08-04 is a Tuesday.
      expect(weekdayForDate(DateTime(2026, 8, 4)), ScheduleWeekday.tuesday);
      expect(weekdayForDate(DateTime(2026, 8, 9)), ScheduleWeekday.sunday);
    });

    test('localDateKey formats YYYY-MM-DD', () {
      expect(localDateKey(DateTime(2026, 8, 4)), '2026-08-04');
    });

    test('tryParseLocalDate accepts valid dates and rejects invalid', () {
      expect(tryParseLocalDate('2026-08-04'), DateTime(2026, 8, 4));
      expect(tryParseLocalDate('2026-02-28'), DateTime(2026, 2, 28));
      expect(tryParseLocalDate('2026-08-4'), isNull);
      expect(tryParseLocalDate('2026-13-01'), isNull);
      expect(tryParseLocalDate('2026-02-31'), isNull);
      expect(tryParseLocalDate('garbage'), isNull);
      expect(tryParseLocalDate('2026-8-04'), isNull);
    });
  });
}
