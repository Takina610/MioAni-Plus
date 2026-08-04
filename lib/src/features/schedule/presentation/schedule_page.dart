import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/features/schedule/application/schedule_providers.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/features/schedule/domain/schedule_builder.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
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
      appBar: AppBar(title: const Text('放送日程')),
      body: SafeArea(
        child: state.failure != null
            ? MioStateView.failure(
                failure: state.failure!,
                onRetry: () => _refresh(ref),
              )
            : state.initialLoading
            ? const MioStateView.loading(label: '正在加载放送日程')
            : _ScheduleContent(state: state, onRefresh: () => _refresh(ref)),
      ),
    );
  }

  void _refresh(WidgetRef ref) {
    ref.read(scheduleControllerProvider(initialDate).notifier).refresh();
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({required this.state, required this.onRefresh});

  final ScheduleState state;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final weekStart = mondayOfWeek(state.localDate);
    final dates = sliceScheduleWindow(weekStart, 7);
    final today = startOfLocalDay(DateTime.now());
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
            if (state.snapshot case final snapshot?) ...<Widget>[
              if (snapshot.isStale)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MioSpacing.lg,
                  ),
                  child: _StaleBanner(snapshot: snapshot, onRetry: onRefresh),
                ),
              const SizedBox(height: MioSpacing.sm),
              Expanded(
                child: compact
                    ? ListView.separated(
                        key: SchedulePage.pageStorageKey,
                        padding: const EdgeInsets.all(MioSpacing.lg),
                        itemCount: dates.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: MioSpacing.md),
                        itemBuilder: (context, index) {
                          return _DayCard(
                            date: dates[index],
                            day: snapshot.value.days[index],
                            isToday:
                                localDateKey(dates[index]) ==
                                localDateKey(today),
                          );
                        },
                      )
                    : SingleChildScrollView(
                        key: SchedulePage.pageStorageKey,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(MioSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            for (
                              var index = 0;
                              index < dates.length;
                              index += 1
                            )
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: MioSpacing.md,
                                ),
                                child: SizedBox(
                                  width: largeText ? 340 : 230,
                                  child: _DayCard(
                                    date: dates[index],
                                    day: snapshot.value.days[index],
                                    isToday:
                                        localDateKey(dates[index]) ==
                                        localDateKey(today),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _goToDate(BuildContext context, DateTime date) {
    ScheduleRouteData(date: localDateKey(date)).go(context);
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

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.snapshot, required this.onRetry});

  final CatalogSnapshot<BroadcastSchedule> snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = snapshot.refreshFailure;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MioSpacing.sm),
      decoration: BoxDecoration(
        color: MioColors.surfaceHigh,
        borderRadius: BorderRadius.circular(MioRadii.sm),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              failure == null
                  ? '正在更新缓存内容…'
                  : '当前显示离线缓存，内容更新时间：${_formatTime(snapshot.fetchedAt)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (failure != null)
            TextButton(onPressed: onRetry, child: const Text('重试更新')),
        ],
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
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

class _ScheduleItemRow extends StatelessWidget {
  const _ScheduleItemRow({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final anime = item.anime;
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return Card(
      margin: const EdgeInsets.only(bottom: MioSpacing.xs),
      color: MioColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          unawaited(
            AnimeDetailRouteData(id: anime.id.value).push<void>(context),
          );
        },
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
