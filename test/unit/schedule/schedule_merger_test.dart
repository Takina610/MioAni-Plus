import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_merger.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

final DateTime _tuesday = DateTime(2026, 8, 4, 12);

AnimeSummary _bgm(int id, String title, {int? episodes, double? score}) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: 'Original $title',
    episodes: episodes,
    score: score,
    airDate: DateTime(2026, 7),
  );
}

AnimeSummary _anilist(int id, String title, {int? episodes, double? score}) {
  return AnimeSummary(
    id: AnimeSourceId.fromAniListId(id),
    title: title,
    sourceTitle: 'Romaji $title',
    episodes: episodes,
    score: score,
  );
}

AniListAiringEntry _donor(AnimeSummary anime, DateTime airingAt) {
  return AniListAiringEntry(anime: anime, airingAt: airingAt);
}

void main() {
  group('normalizeTitleKey', () {
    test('normalizes case, punctuation and season markers', () {
      expect(normalizeTitleKey('  SAO II（第二季）  '), 'saoii二');
      expect(normalizeTitleKey('夏日重现 第2期'), '夏日重现2');
      expect(normalizeTitleKey('Fate/stay night'), 'fatestaynight');
      expect(normalizeTitleKey('少女☆歌剧'), '少女歌剧');
      // Full-width ASCII folds to half-width for cross-source matching.
      expect(normalizeTitleKey('ＳＡＯ ＩＩ'), 'saoii');
    });
  });

  group('isSameAnime', () {
    test('matches across Bangumi and AniList titles', () {
      final bangumi = _bgm(1, '进击的巨人 最终季');
      final anilist = _anilist(99, '进击的巨人 最终季', episodes: 16);
      expect(isSameAnime(bangumi, anilist), isTrue);
    });

    test('rejects unrelated shows', () {
      expect(isSameAnime(_bgm(1, '某科学的超电磁炮'), _anilist(99, '间谍过家家')), isFalse);
    });

    test('rejects incompatible years', () {
      final old = AnimeSummary(
        id: AnimeSourceId.fromBangumiId(1),
        title: '高达',
        sourceTitle: 'Gundam',
        airDate: DateTime(1979, 1),
      );
      final modern = AnimeSummary(
        id: AnimeSourceId.fromAniListId(99),
        title: '高达',
        sourceTitle: 'Gundam',
        airDate: DateTime(2022, 1),
      );
      expect(isSameAnime(old, modern), isFalse);
    });
  });

  group('buildScheduleFromAniList', () {
    test('maps Unix airing moments into the weekly template', () {
      final days = buildScheduleFromAniList([
        _donor(_anilist(1, '周三番'), DateTime(2026, 8, 5, 23, 30)),
        _donor(_anilist(2, '周二番'), DateTime(2026, 8, 4, 1, 5)),
      ], _tuesday);

      final wednesday = days.firstWhere(
        (day) => day.weekday == ScheduleWeekday.wednesday,
      );
      expect(wednesday.items.single.airTime?.text, '23:30');

      final tuesday = days.firstWhere(
        (day) => day.weekday == ScheduleWeekday.tuesday,
      );
      expect(tuesday.items.single.airTime?.text, '01:05');
    });

    test('produces empty template for no donors', () {
      final days = buildScheduleFromAniList(const [], _tuesday);
      expect(scheduleHasContent(days), isFalse);
    });
  });

  group('enrichScheduleWithAiringTimes', () {
    test('fills missing time and episode/score from a matching donor', () {
      final days = buildWeekSchedule([
        ScheduleSourceItem(
          anime: _bgm(2, '夏日重现'),
          weekday: ScheduleWeekday.tuesday,
        ),
      ], _tuesday);

      final enriched = enrichScheduleWithAiringTimes(days, [
        _donor(
          _anilist(9, '夏日重现', episodes: 25, score: 8.7),
          DateTime(2026, 8, 4, 22, 15),
        ),
      ], _tuesday);

      final item = enriched
          .firstWhere((day) => day.weekday == ScheduleWeekday.tuesday)
          .items
          .single;
      expect(item.timed, isTrue);
      expect(item.airTime?.text, '22:15');
      expect(item.anime.episodes, 25);
      expect(item.anime.score, 8.7);
    });

    test('returns input unchanged when no donor matches', () {
      final days = buildWeekSchedule([
        ScheduleSourceItem(
          anime: _bgm(2, '夏日重现'),
          weekday: ScheduleWeekday.tuesday,
        ),
      ], _tuesday);

      final enriched = enrichScheduleWithAiringTimes(days, [
        _donor(_anilist(9, '间谍过家家'), DateTime(2026, 8, 4, 22, 15)),
      ], _tuesday);

      expect(enriched, same(days));
      expect(
        enriched
            .firstWhere((day) => day.weekday == ScheduleWeekday.tuesday)
            .items
            .single
            .timed,
        isFalse,
      );
    });

    test('keeps existing time when donor also provides one', () {
      final days = buildWeekSchedule([
        ScheduleSourceItem(
          anime: _bgm(2, '夏日重现'),
          weekday: ScheduleWeekday.tuesday,
          airTime: ScheduleTime.fromHourMinute(20, 0),
        ),
      ], _tuesday);

      final enriched = enrichScheduleWithAiringTimes(days, [
        _donor(_anilist(9, '夏日重现'), DateTime(2026, 8, 4, 22, 15)),
      ], _tuesday);

      expect(
        enriched
            .firstWhere((day) => day.weekday == ScheduleWeekday.tuesday)
            .items
            .single
            .airTime
            ?.text,
        '20:00',
      );
      expect(enriched, same(days));
    });

    test('does nothing for an empty template', () {
      final days = buildWeekSchedule(const [], _tuesday);
      final enriched = enrichScheduleWithAiringTimes(days, [
        _donor(_anilist(9, '夏日重现'), DateTime(2026, 8, 4, 22, 15)),
      ], _tuesday);
      expect(enriched, same(days));
    });
  });
}
