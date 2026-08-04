import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

/// An AniList entry carrying its next airing moment, used as a donor for
/// enriching the Bangumi weekly template.
class AniListAiringEntry {
  const AniListAiringEntry({required this.anime, required this.airingAt});

  final AnimeSummary anime;

  /// Local calendar date/time of the next airing (converted from Unix seconds
  /// at the source boundary).
  final DateTime airingAt;

  ScheduleTime get airTime => ScheduleTime.fromLocalDateTime(airingAt);
  ScheduleWeekday get weekday => ScheduleWeekday.fromLocalDate(airingAt);
}

/// Normalizes a title for fuzzy cross-source matching: NFKC-like
/// compatibility folding, strips punctuation/whitespace and trailing season
/// markers.
String normalizeTitleKey(String value) {
  final normalized = _foldCompatibility(value.toLowerCase())
      .replaceAll(RegExp(r'[\u200b-\u200d\ufeff]'), '')
      .replaceAll(
        RegExp(r'''[【】\[\]「」『』〈〉《》()（）·・\s._\-—–:'"“”‘’!！?？,，.。/\\|+☆★♪~～]'''),
        '',
      )
      .replaceAllMapped(
        RegExp(r'第([0-9一二三四五六七八九十]+)[期季部]'),
        (match) => match.group(1)!,
      )
      .replaceAllMapped(
        RegExp(r'(season|cour|part)([0-9]+)'),
        (match) => match.group(2)!,
      )
      .trim();
  return normalized;
}

List<String> collectTitleKeys(AnimeSummary anime) {
  final raw = <String?>[anime.title, anime.sourceTitle];
  return <String>{
    for (final value in raw) normalizeTitleKey(value ?? ''),
  }.where((key) => key.isNotEmpty).toList(growable: false);
}

/// Loose equality used only to decide whether an AniList row may enrich a
/// Bangumi row. Title key overlap must hold; years may differ by at most one
/// and episode counts by at most six. This matching never writes to anime
/// identity tables.
bool isSameAnime(AnimeSummary a, AnimeSummary b) {
  final aKeys = collectTitleKeys(a);
  final bKeys = collectTitleKeys(b);
  if (aKeys.isEmpty || bKeys.isEmpty) return false;
  final shareTitle = aKeys.any(bKeys.contains);
  if (!shareTitle) return false;

  final yearA = a.airDate?.year ?? 0;
  final yearB = b.airDate?.year ?? 0;
  if (yearA != 0 && yearB != 0 && (yearA - yearB).abs() > 1) return false;

  final episodesA = a.episodes ?? 0;
  final episodesB = b.episodes ?? 0;
  if (episodesA != 0 &&
      episodesB != 0 &&
      (episodesA - episodesB).abs() > 6 &&
      episodesA >= 3 &&
      episodesB >= 3) {
    return false;
  }

  return true;
}

/// AniList fallback schedule: groups `nextAiringEpisode` times into the same
/// fixed weekly template. Used when the Bangumi calendar is unavailable.
List<ScheduleDay> buildScheduleFromAniList(
  Iterable<AniListAiringEntry> entries,
  DateTime now,
) {
  return buildWeekSchedule(<ScheduleSourceItem>[
    for (final entry in entries)
      ScheduleSourceItem(
        anime: entry.anime,
        weekday: entry.weekday,
        airTime: entry.airTime,
      ),
  ], now);
}

/// Fills missing airing times / episode counts / scores on Bangumi calendar
/// rows from matching AniList donors. Returns the input unchanged when nothing
/// could be filled, so a failed enrichment never corrupts the Bangumi baseline.
List<ScheduleDay> enrichScheduleWithAiringTimes(
  List<ScheduleDay> days,
  Iterable<AniListAiringEntry> donors,
  DateTime now,
) {
  if (!scheduleHasContent(days)) return days;
  final donorList = donors.toList(growable: false);
  if (donorList.isEmpty) return days;

  final sources = <ScheduleSourceItem>[];
  var changed = 0;
  for (final day in days) {
    for (final item in day.items) {
      var airTime = item.airTime;
      var weekday = item.weekday;
      var anime = item.anime;
      for (final donor in donorList) {
        if (!isSameAnime(item.anime, donor.anime)) continue;
        if (airTime == null) {
          airTime = donor.airTime;
          weekday = donor.weekday;
          changed += 1;
        }
        if ((anime.episodes ?? 0) <= 0 && (donor.anime.episodes ?? 0) > 0) {
          anime = _copyWithEpisodes(anime, donor.anime.episodes);
          changed += 1;
        }
        if ((anime.score ?? 0) <= 0 && (donor.anime.score ?? 0) > 0) {
          anime = _copyWithScore(anime, donor.anime.score);
          changed += 1;
        }
        break;
      }
      sources.add(
        ScheduleSourceItem(anime: anime, weekday: weekday, airTime: airTime),
      );
    }
  }

  if (changed == 0) return days;
  return buildWeekSchedule(sources, now);
}

AnimeSummary _copyWithEpisodes(AnimeSummary anime, int? episodes) {
  return AnimeSummary(
    id: anime.id,
    title: anime.title,
    sourceTitle: anime.sourceTitle,
    imageUrl: anime.imageUrl,
    score: anime.score,
    airDate: anime.airDate,
    summary: anime.summary,
    episodes: episodes,
    popularity: anime.popularity,
  );
}

AnimeSummary _copyWithScore(AnimeSummary anime, double? score) {
  return AnimeSummary(
    id: anime.id,
    title: anime.title,
    sourceTitle: anime.sourceTitle,
    imageUrl: anime.imageUrl,
    score: score,
    airDate: anime.airDate,
    summary: anime.summary,
    episodes: anime.episodes,
    popularity: anime.popularity,
  );
}

/// Best-effort compatibility folding without adding an ICU dependency:
/// full-width ASCII letters/digits and common Roman numerals to ASCII.
/// CJK input is already compatible, so only these ranges are mapped.
String _foldCompatibility(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune >= 0xFF01 && rune <= 0xFF5E) {
      buffer.writeCharCode(rune - 0xFEE0);
    } else if (rune == 0x3000) {
      buffer.write(' ');
    } else if (rune >= 0x2160 && rune <= 0x216B) {
      buffer.write(_romanNumeral(rune - 0x2160));
    } else if (rune >= 0x2170 && rune <= 0x217B) {
      buffer.write(_romanNumeral(rune - 0x2170));
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

String _romanNumeral(int index) {
  const numerals = <String>[
    'i',
    'ii',
    'iii',
    'iv',
    'v',
    'vi',
    'vii',
    'viii',
    'ix',
    'x',
    'xi',
    'xii',
  ];
  return numerals[index];
}
