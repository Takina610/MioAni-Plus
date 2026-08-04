import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

/// One broadcast entry inside a `ScheduleDay`.
class ScheduleItem {
  const ScheduleItem({
    required this.anime,
    required this.weekday,
    required this.timed,
    this.airTime,
  });

  final AnimeSummary anime;

  /// The weekday the show airs on within the fixed Mon→Sun template.
  final ScheduleWeekday weekday;

  /// True when a real local `HH:mm` is known; otherwise the UI shows 待定.
  final bool timed;
  final ScheduleTime? airTime;
}

/// A single slot of the fixed Monday→Sunday weekly template.
class ScheduleDay {
  const ScheduleDay({
    required this.weekday,
    required this.label,
    required this.isToday,
    required this.items,
  });

  final ScheduleWeekday weekday;
  final String label;
  final bool isToday;
  final List<ScheduleItem> items;
}

/// A complete week template. Freshness and refresh failures travel in the
/// surrounding [CatalogSnapshot] rather than being duplicated here.
class BroadcastSchedule {
  const BroadcastSchedule({required this.generatedAt, required this.days});

  final DateTime generatedAt;
  final List<ScheduleDay> days;
}
