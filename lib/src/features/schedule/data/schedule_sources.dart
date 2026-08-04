import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_merger.dart';

/// Fetch boundary for the Bangumi `/calendar` weekly template.
abstract interface class ScheduleCalendarSource {
  Future<List<ScheduleSourceItem>> fetchCalendar({
    bool forceNewGeneration = false,
  });
}

/// Fetch boundary for AniList `nextAiringEpisode` enrichment donors.
abstract interface class AniListAiringSource {
  Future<List<AniListAiringEntry>> fetchAiringEntries({
    bool forceNewGeneration = false,
  });
}
