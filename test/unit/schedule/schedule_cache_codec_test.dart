import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/schedule/data/schedule_cache_codec.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

void main() {
  final codec = const ScheduleCacheCodec();

  test('round-trips a full week with timed and untimed items', () {
    final schedule = BroadcastSchedule(
      generatedAt: DateTime(2026, 8, 4, 12),
      days: buildWeekSchedule(<ScheduleSourceItem>[
        ScheduleSourceItem(
          anime: _anime(1, '第一季'),
          weekday: ScheduleWeekday.monday,
          airTime: ScheduleTime.fromHourMinute(22, 30),
        ),
        ScheduleSourceItem(
          anime: _anime(2, '待定动画'),
          weekday: ScheduleWeekday.monday,
        ),
        ScheduleSourceItem(
          anime: _anime(3, '周二动画'),
          weekday: ScheduleWeekday.tuesday,
        ),
      ], DateTime(2026, 8, 4)),
    );

    final decoded = codec.decodeWeek(codec.encodeWeek(schedule));

    expect(decoded.generatedAt, DateTime(2026, 8, 4, 12));
    expect(decoded.days, hasLength(7));
    expect(decoded.days.map((day) => day.weekday), ScheduleWeekday.values);
    final monday = decoded.days.first;
    expect(monday.items, hasLength(2));
    expect(monday.items.first.airTime, ScheduleTime.fromHourMinute(22, 30));
    expect(monday.items.first.timed, isTrue);
    expect(monday.items.last.timed, isFalse);
    expect(monday.items.first.anime.title, '第一季');
    expect(monday.items.first.anime.id, AnimeSourceId.fromBangumiId(1));
    expect(monday.items.first.anime.popularity, 99);
    // Derived display state is never persisted.
    expect(decoded.days.every((day) => day.isToday), isFalse);
  });

  test('rejects malformed week payloads', () {
    final sixDays = jsonEncode(<String, Object?>{
      'generatedAt': DateTime(2026, 8, 4).toIso8601String(),
      'days': <Object?>[
        for (var i = 0; i < 6; i += 1)
          <String, Object?>{'weekday': i + 1, 'items': <Object?>[]},
      ],
    });
    expect(() => codec.decodeWeek(sixDays), throwsFormatException);

    final missingWeekday = jsonEncode(<String, Object?>{
      'generatedAt': DateTime(2026, 8, 4).toIso8601String(),
      'days': <Object?>[
        for (var i = 0; i < 7; i += 1)
          <String, Object?>{'weekday': null, 'items': <Object?>[]},
      ],
    });
    expect(() => codec.decodeWeek(missingWeekday), throwsFormatException);

    final timedWithoutTime = jsonEncode(<String, Object?>{
      'generatedAt': DateTime(2026, 8, 4).toIso8601String(),
      'days': <Object?>[
        for (var weekday = 1; weekday <= 7; weekday += 1)
          <String, Object?>{
            'weekday': weekday,
            'items': <Object?>[
              if (weekday == 1)
                <String, Object?>{
                  'anime': <String, Object?>{
                    'id': 'bgm-1',
                    'title': '动画',
                    'sourceTitle': '',
                  },
                  'timed': true,
                  'airTime': null,
                },
            ],
          },
      ],
    });
    expect(() => codec.decodeWeek(timedWithoutTime), throwsFormatException);
  });
}

AnimeSummary _anime(int id, String title) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(id),
    title: title,
    sourceTitle: '',
    imageUrl: Uri.parse('https://lain.bgm.tv/pic/cover/l/$id.jpg'),
    score: 7.5,
    popularity: 99,
  );
}
