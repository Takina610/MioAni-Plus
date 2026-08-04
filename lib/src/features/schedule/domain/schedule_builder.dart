import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

typedef ScheduleNow = DateTime Function();

/// An unresolved entry fed into [buildWeekSchedule].
///
/// The airing time may still be unknown (待定); only entries with a known
/// weekday slot are kept.
class ScheduleSourceItem {
  const ScheduleSourceItem({
    required this.anime,
    required this.weekday,
    this.airTime,
  });

  final AnimeSummary anime;
  final ScheduleWeekday weekday;
  final ScheduleTime? airTime;
}

/// Builds the fixed Monday→Sunday weekly template.
///
/// - Deduplicates by source anime id; the first occurrence of an id wins so a
///   show appearing in two template days is never counted twice.
/// - Timed items sort by `HH:mm` ascending; untimed (待定) entries follow,
///   ordered by popularity desc then title, matching the Vue reference.
/// - All ordering is stable and platform independent.
List<ScheduleDay> buildWeekSchedule(
  Iterable<ScheduleSourceItem> sources,
  DateTime now,
) {
  final today = ScheduleWeekday.fromLocalDate(now);
  final buckets = <ScheduleWeekday, List<ScheduleItem>>{
    for (final weekday in ScheduleWeekday.values) weekday: <ScheduleItem>[],
  };
  final seen = <String>{};
  for (final source in sources) {
    if (!seen.add(source.anime.id.value)) continue;
    buckets[source.weekday]?.add(
      ScheduleItem(
        anime: source.anime,
        weekday: source.weekday,
        timed: source.airTime != null,
        airTime: source.airTime,
      ),
    );
  }

  return <ScheduleDay>[
    for (final weekday in ScheduleWeekday.values)
      ScheduleDay(
        weekday: weekday,
        label: weekday.label,
        isToday: weekday == today,
        items: buckets[weekday]!.toList(growable: false)..sort(_compareItems),
      ),
  ];
}

/// Sorts a day's items: known times first (ascending), then popularity desc,
/// then stable title ordering. Untimed items always follow timed ones.
int _compareItems(ScheduleItem a, ScheduleItem b) {
  if (a.timed != b.timed) return a.timed ? -1 : 1;
  if (a.timed && b.timed) {
    final byTime = (a.airTime ?? ScheduleTime.min).compareTo(
      b.airTime ?? ScheduleTime.min,
    );
    if (byTime != 0) return byTime;
  }
  final byPopularity = (b.anime.popularity ?? 0).compareTo(
    a.anime.popularity ?? 0,
  );
  if (byPopularity != 0) return byPopularity;
  final byTitle = a.anime.title.compareTo(b.anime.title);
  if (byTitle != 0) return byTitle;
  return a.anime.id.value.compareTo(b.anime.id.value);
}

/// An empty Monday→Sunday template for a fully offline/empty state.
List<ScheduleDay> emptyWeekSchedule(DateTime now) {
  return buildWeekSchedule(const <ScheduleSourceItem>[], now);
}

bool scheduleHasContent(Iterable<ScheduleDay> days) {
  return days.any((day) => day.items.isNotEmpty);
}

/// Picks the `limit` most relevant entries across the whole week for the
/// home “最近更新” rail. Deduplicates by source id, then applies the same
/// stable ordering as a single day.
List<ScheduleItem> flattenRecentSchedule(
  Iterable<ScheduleDay> days,
  int limit,
) {
  final seen = <String>{};
  final out = <ScheduleItem>[];
  for (final day in days) {
    for (final item in day.items) {
      if (!seen.add(item.anime.id.value)) continue;
      out.add(item);
    }
  }
  out.sort(_compareItems);
  final count = limit < 0 ? 0 : limit;
  return out.take(count).toList(growable: false);
}

/// Local calendar midnight for [date] (time-of-day zeroed).
DateTime startOfLocalDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// [date] shifted by [days] local calendar days (DST-safe).
DateTime addLocalDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days);
}

/// Inclusive window of local midnights starting at [start].
List<DateTime> sliceScheduleWindow(DateTime start, int columns) {
  final base = startOfLocalDay(start);
  final count = columns < 0 ? 0 : columns;
  return <DateTime>[
    for (var index = 0; index < count; index += 1) addLocalDays(base, index),
  ];
}

/// The Monday midnight that starts the local week containing [date].
DateTime mondayOfWeek(DateTime date) {
  final base = startOfLocalDay(date);
  return addLocalDays(base, 1 - date.weekday);
}

/// The weekday a local calendar date falls on.
ScheduleWeekday weekdayForDate(DateTime date) {
  return ScheduleWeekday.fromLocalDate(date);
}

/// `M/d` label for schedule column headers.
String formatScheduleMonthDay(DateTime date) => '${date.month}/${date.day}';

/// Local date key (`YYYY-MM-DD`) used by `/schedule?date=`.
String localDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Parses a strict `YYYY-MM-DD` local date; invalid input returns `null`.
DateTime? tryParseLocalDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  // Reject rolled-over values such as 2026-02-31.
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}
