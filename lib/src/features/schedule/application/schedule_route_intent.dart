import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';

/// Normalizes the `/schedule?date=` query into a local calendar date.
///
/// Unknown, malformed or rolled-over values fall back to today and are
/// normalized to local midnight; valid dates keep their local calendar day.
DateTime normalizeScheduleDate(String? raw, {DateTime Function()? now}) {
  final clock = now ?? DateTime.now;
  final parsed = raw == null ? null : tryParseLocalDate(raw);
  return startOfLocalDay(parsed ?? clock());
}
