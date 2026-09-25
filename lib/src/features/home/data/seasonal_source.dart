import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// Fetch boundary for a source's own ranking of one season.
///
/// The Bangumi calendar is a weekly template: it lists everything that still
/// airs, so the season filter has to be applied on top of it. This port is for
/// a source that already answers "what is this season's lineup", and it stands
/// in when the calendar carries no entry for the season yet (the days around a
/// season change) or cannot be reached.
abstract interface class SeasonalAnimeSource {
  Future<List<AnimeSummary>> fetchSeason({bool forceNewGeneration = false});
}
