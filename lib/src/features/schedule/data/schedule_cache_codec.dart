import 'dart:convert';

import 'package:mio_ani/src/features/catalog/data/anime_summary_codec.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_time.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';

/// JSON codec for the cached weekly template.
///
/// `isToday` and `label` are derived state (they depend on the read time), so
/// only weekday anchors and items are persisted; the repository re-derives
/// them before emitting.
final class ScheduleCacheCodec {
  const ScheduleCacheCodec({this.summaryCodec = const AnimeSummaryCodec()});

  final AnimeSummaryCodec summaryCodec;

  String encodeWeek(BroadcastSchedule schedule) {
    return jsonEncode(<String, Object?>{
      'generatedAt': schedule.generatedAt.toIso8601String(),
      'days': <Object?>[
        for (final day in schedule.days)
          <String, Object?>{
            'weekday': day.weekday.bangumiId,
            'items': <Object?>[for (final item in day.items) _itemToJson(item)],
          },
      ],
    });
  }

  BroadcastSchedule decodeWeek(String payload) {
    final decoded = jsonDecode(payload);
    final map = summaryCodec.objectMap(decoded, 'Schedule week cache');
    final generatedText = summaryCodec.nullableString(map['generatedAt']);
    final generatedAt = generatedText == null
        ? null
        : DateTime.tryParse(generatedText);
    if (generatedAt == null) {
      throw const FormatException('Schedule cache is missing generatedAt');
    }
    final rawDays = map['days'];
    if (rawDays is! List<Object?> || rawDays.length != 7) {
      throw const FormatException('Schedule cache must contain seven days');
    }
    final days = <ScheduleDay>[
      for (final rawDay in rawDays)
        _decodeDay(summaryCodec.objectMap(rawDay, 'Schedule cache day')),
    ];
    return BroadcastSchedule(generatedAt: generatedAt, days: days);
  }

  Map<String, Object?> _itemToJson(ScheduleItem item) {
    final anime = item.anime;
    return <String, Object?>{
      'anime': summaryCodec.toJson(anime),
      'timed': item.timed,
      'airTime': item.airTime?.text,
    };
  }

  ScheduleDay _decodeDay(Map<String, Object?> map) {
    final weekdayId = summaryCodec.nullableInt(map['weekday']);
    if (weekdayId == null) {
      throw const FormatException('Schedule cache is missing weekday');
    }
    final weekday = ScheduleWeekday.fromBangumiId(weekdayId);
    final rawItems = map['items'];
    if (rawItems is! List<Object?>) {
      throw const FormatException('Schedule cache items must be a list');
    }
    final items = <ScheduleItem>[
      for (final rawItem in rawItems)
        _decodeItem(
          summaryCodec.objectMap(rawItem, 'Schedule cache item'),
          weekday,
        ),
    ];
    return ScheduleDay(
      weekday: weekday,
      label: weekday.label,
      isToday: false,
      items: items,
    );
  }

  ScheduleItem _decodeItem(Map<String, Object?> map, ScheduleWeekday weekday) {
    final timed = map['timed'];
    if (timed is! bool) {
      throw const FormatException('Schedule cache item timed must be a bool');
    }
    final airText = summaryCodec.nullableString(map['airTime']);
    final airTime = airText == null ? null : ScheduleTime.tryParse(airText);
    if (timed && airTime == null) {
      throw const FormatException('Timed schedule item is missing a time');
    }
    return ScheduleItem(
      anime: summaryCodec.fromJson(
        summaryCodec.objectMap(map['anime'], 'Schedule cache anime'),
      ),
      weekday: weekday,
      timed: timed,
      airTime: airTime,
    );
  }
}
