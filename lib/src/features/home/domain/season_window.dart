/// Local-calendar window of the broadcast season that contains [now].
///
/// Seasons are the calendar quarters the catalogues cut them on: winter starts
/// in January, spring in April, summer in July and fall in October. The window
/// is half-open — [start] is included, [end] is excluded — so a show that
/// premieres on the first day of a season counts as that season's, and one that
/// premieres on the first day of the next does not.
({DateTime start, DateTime end}) currentSeasonWindow(DateTime now) {
  final startMonth = ((now.month - 1) ~/ 3) * 3 + 1;
  return (
    start: DateTime(now.year, startMonth),
    end: DateTime(now.year, startMonth + 3),
  );
}

/// Whether [airDate] falls inside the season that contains [now].
///
/// A show that premiered in an earlier season keeps airing every week and so
/// stays on the calendar, but it is not part of the current season's lineup.
/// Entries without a premiere date cannot be placed in a season at all.
bool isInCurrentSeason(DateTime? airDate, DateTime now) {
  if (airDate == null) return false;
  final window = currentSeasonWindow(now);
  return !airDate.isBefore(window.start) && airDate.isBefore(window.end);
}
