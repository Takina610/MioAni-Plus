import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/anime_detail_navigation.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_providers.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_weekday.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({required this.initialDate, super.key});

  final DateTime initialDate;

  static const PageStorageKey<String> pageStorageKey = PageStorageKey<String>(
    'schedule-content',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleControllerProvider(initialDate));
    return Scaffold(
      // The brand backdrop belongs to the shell, behind every branch.
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('放送日程')),
      body: SafeArea(
        child: state.failure != null
            ? MioStateView.failure(
                failure: state.failure!,
                onRetry: () => _refresh(ref),
              )
            : _ScheduleContent(state: state),
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    ref.read(scheduleControllerProvider(initialDate).notifier).refresh();
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({required this.state});

  final ScheduleState state;

  @override
  Widget build(BuildContext context) {
    final weekStart = mondayOfWeek(state.localDate);
    final dates = sliceScheduleWindow(weekStart, 7);
    final today = startOfLocalDay(DateTime.now());
    final snapshot = state.snapshot;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            MioBreakpoints.windowClassFor(constraints.maxWidth) ==
            MioWindowClass.compact;
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
        final weekLabel =
            '${formatScheduleMonthDay(dates.first)} – '
            '${formatScheduleMonthDay(dates.last)}';
        return Column(
          children: <Widget>[
            _WeekNavigator(
              weekStart: weekStart,
              weekLabel: weekLabel,
              onPrevious: () => _goToDate(context, addLocalDays(weekStart, -7)),
              onNext: () => _goToDate(context, addLocalDays(weekStart, 7)),
              onToday: () => _goToDate(context, today),
            ),
            const SizedBox(height: MioSpacing.sm),
            // The week is the route's, not the answer's: the seven days and
            // their names are known before the schedule is, so a week still
            // being read is drawn as the week it will be, with the rows that are
            // still coming standing empty in place. Nothing on the page moves
            // when the answer lands, and no day is a spinner.
            Expanded(
              child: _ScheduleWindow(
                dates: dates,
                compact: compact,
                largeText: largeText,
                today: today,
                dayBuilder: (context, index, isToday) {
                  final day = snapshot?.value.days[index];
                  return day == null
                      ? _DayCardPlaceholder(
                          date: dates[index],
                          isToday: isToday,
                        )
                      : _DayCard(
                          date: dates[index],
                          day: day,
                          isToday: isToday,
                        );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _goToDate(BuildContext context, DateTime date) {
    ScheduleRouteData(date: localDateKey(date)).go(context);
  }
}

/// The week's own arrangement: one day per row on a phone, the seven days side
/// by side on a wide window. Every state of the page is laid out through it, so
/// a week being read and a week already read stand the same way.
class _ScheduleWindow extends StatelessWidget {
  const _ScheduleWindow({
    required this.dates,
    required this.compact,
    required this.largeText,
    required this.today,
    required this.dayBuilder,
  });

  final List<DateTime> dates;
  final bool compact;
  final bool largeText;
  final DateTime today;
  final Widget Function(BuildContext context, int index, bool isToday)
  dayBuilder;

  @override
  Widget build(BuildContext context) {
    bool isToday(DateTime date) => localDateKey(date) == localDateKey(today);
    if (compact) {
      return ListView.separated(
        key: SchedulePage.pageStorageKey,
        padding: const EdgeInsets.all(MioSpacing.lg),
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(height: MioSpacing.md),
        itemBuilder: (context, index) =>
            dayBuilder(context, index, isToday(dates[index])),
      );
    }
    return SingleChildScrollView(
      key: SchedulePage.pageStorageKey,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(MioSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var index = 0; index < dates.length; index += 1)
            Padding(
              padding: const EdgeInsets.only(right: MioSpacing.md),
              child: SizedBox(
                width: largeText ? 340 : 230,
                child: dayBuilder(context, index, isToday(dates[index])),
              ),
            ),
        ],
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.weekLabel,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime weekStart;
  final String weekLabel;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final year = weekStart.year;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MioSpacing.lg,
        MioSpacing.md,
        MioSpacing.lg,
        MioSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '上一周',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                children: <Widget>[
                  Text(
                    weekLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '$year 年第${_weekNumber(weekStart)}周',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: '下一周',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: MioSpacing.xs),
          FilledButton.tonal(onPressed: onToday, child: const Text('今天')),
        ],
      ),
    );
  }

  int _weekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final days = date.difference(jan1).inDays;
    return ((days + jan1.weekday - 1) ~/ 7) + 1;
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.day,
    required this.isToday,
  });

  final DateTime date;
  final ScheduleDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isToday ? MioColors.surfaceHigh : MioColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(MioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Row(
                children: <Widget>[
                  Text(
                    day.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: MioSpacing.sm),
                  Text(
                    '${date.month}/${date.day}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (isToday) ...<Widget>[
                    const SizedBox(width: MioSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: MioSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: MioColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '今天',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: MioColors.onAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MioSpacing.sm),
            if (day.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: MioSpacing.md),
                child: Text(
                  '暂无放送安排',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              for (final item in day.items) _ScheduleItemRow(item: item),
          ],
        ),
      ),
    );
  }
}

/// One day of a week that is still being read.
///
/// The day itself is not in question — it is the date the reader is looking at,
/// down to its name and whether it is today — so the card keeps its heading and
/// stands [rows] empty rows where the day's shows will go. Each row is drawn as
/// the row it replaces, a card of its own, so a placeholder on today's card
/// stands out the way the real pile of shows will.
class _DayCardPlaceholder extends StatelessWidget {
  const _DayCardPlaceholder({required this.date, required this.isToday});

  final DateTime date;
  final bool isToday;

  /// Rows of the shape [_ScheduleItemRow] takes: a time, a title, a chevron.
  static const int rows = 3;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isToday ? MioColors.surfaceHigh : MioColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(MioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  ScheduleWeekday.fromLocalDate(date).label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: MioSpacing.sm),
                Text(
                  '${date.month}/${date.day}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: MioSpacing.sm),
            for (var row = 0; row < rows; row += 1)
              Card(
                margin: const EdgeInsets.only(bottom: MioSpacing.xs),
                color: MioColors.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MioSpacing.sm,
                    vertical: MioSpacing.xs,
                  ),
                  child: Row(
                    children: <Widget>[
                      const SizedBox(
                        width: 48,
                        child: MioPlaceholder(
                          width: 40,
                          height: 16,
                          radius: MioRadii.sm,
                        ),
                      ),
                      const SizedBox(width: MioSpacing.xs),
                      const Expanded(
                        child: MioPlaceholder(height: 20, radius: MioRadii.sm),
                      ),
                      const SizedBox(width: MioSpacing.xs),
                      const MioPlaceholder(
                        width: 20,
                        height: 20,
                        radius: MioRadii.sm,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItemRow extends ConsumerWidget {
  const _ScheduleItemRow({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anime = item.anime;
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return Card(
      margin: const EdgeInsets.only(bottom: MioSpacing.xs),
      color: MioColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openAnimeDetail(context, ref, anime),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MioSpacing.sm,
            vertical: MioSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 48,
                child: Text(
                  item.timed ? item.airTime!.text : '待定',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: item.timed
                        ? MioColors.accent
                        : MioColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: MioSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
