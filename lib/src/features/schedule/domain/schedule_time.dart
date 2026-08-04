/// A normalized local `HH:mm` airing time.
///
/// Parsing accepts `HH:mm` and the compact forms used by Bangumi/AniList
/// (`2330`, `930`, `9:05`). Invalid hours/minutes return `null` so a bad field
/// is dropped without failing the whole schedule.
final class ScheduleTime implements Comparable<ScheduleTime> {
  const ScheduleTime._(this.hour, this.minute);

  static const ScheduleTime min = ScheduleTime._(0, 0);
  static const ScheduleTime max = ScheduleTime._(23, 59);

  final int hour;
  final int minute;

  String get text =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  int get minutesSinceMidnight => hour * 60 + minute;

  static ScheduleTime? tryParse(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;

    int? hour;
    int? minute;
    final colon = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
    if (colon != null) {
      hour = int.tryParse(colon.group(1)!);
      minute = int.tryParse(colon.group(2)!);
    } else {
      final digits = text.replaceAll(RegExp(r'\D'), '');
      if (digits.length == 3 || digits.length == 4) {
        final padded = digits.padLeft(4, '0');
        hour = int.tryParse(padded.substring(0, 2));
        minute = int.tryParse(padded.substring(2, 4));
      }
    }
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return ScheduleTime._(hour, minute);
  }

  static ScheduleTime fromLocalDateTime(DateTime value) {
    return ScheduleTime._(value.hour, value.minute);
  }

  static ScheduleTime fromHourMinute(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('invalid time $hour:$minute');
    }
    return ScheduleTime._(hour, minute);
  }

  @override
  int compareTo(ScheduleTime other) {
    return minutesSinceMidnight.compareTo(other.minutesSinceMidnight);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleTime &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => text;
}
