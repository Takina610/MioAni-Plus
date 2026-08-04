/// Local weekday used by schedule days. `monday == 1` … `sunday == 7` follows
/// the Bangumi `/calendar` convention and makes Monday-first ordering trivial.
///
/// Conversion to and from Dart's `DateTime.weekday` is explicit so every local
/// date maps onto the fixed seven-day template without calendar API drift.
enum ScheduleWeekday {
  monday(1, '周一'),
  tuesday(2, '周二'),
  wednesday(3, '周三'),
  thursday(4, '周四'),
  friday(5, '周五'),
  saturday(6, '周六'),
  sunday(7, '周日');

  const ScheduleWeekday(this.bangumiId, this.label);

  /// Bangumi `/calendar` `weekday.id` value (1=Mon … 7=Sun).
  final int bangumiId;
  final String label;

  static ScheduleWeekday fromBangumiId(int id) {
    for (final value in values) {
      if (value.bangumiId == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'not a Bangumi weekday id');
  }

  /// Maps any Java-style weekday (1=Mon … 7=Sun) with clamping.
  static ScheduleWeekday fromBangumiIdOrSunday(int id) {
    if (id < 1 || id > 7) return sunday;
    return fromBangumiId(id);
  }

  /// Converts a local calendar day into its fixed weekly slot.
  static ScheduleWeekday fromLocalDate(DateTime date) {
    return values[date.weekday - 1];
  }
}
