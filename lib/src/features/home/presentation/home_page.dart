import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/presentation/catalog_tracer_page.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/presentation/hero_prefetch.dart';
import 'package:mio_ani/src/features/schedule/domain/broadcast_schedule.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const PageStorageKey<String> pageStorageKey = PageStorageKey<String>(
    'home-content',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(homeControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(homeControllerProvider.notifier).refresh();
            await ref.read(homeStreamProvider.future);
          },
          child: CustomScrollView(
            key: pageStorageKey,
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _HomeHeader(
                  snapshot: snapshot,
                  onRetry: () => _requestRefresh(ref),
                ),
              ),
              if (snapshot.catalog.value?.hero case final hero?
                  when hero.isNotEmpty)
                SliverToBoxAdapter(
                  child: _HeroCarouselSection(
                    hero: hero,
                    status: snapshot.catalog.status,
                  ),
                ),
              SliverToBoxAdapter(
                child: _CatalogSections(
                  snapshot: snapshot,
                  onRetry: () => _requestRefresh(ref),
                ),
              ),
              SliverToBoxAdapter(
                child: _ScheduleSections(
                  snapshot: snapshot,
                  onRetry: () => _requestRefresh(ref),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: MioSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  void _requestRefresh(WidgetRef ref) {
    ref.read(homeControllerProvider.notifier).refresh();
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.snapshot, required this.onRetry});

  final HomeSnapshot snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MioSpacing.lg,
        MioSpacing.lg,
        MioSpacing.lg,
        MioSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              'MioAni',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: MioSpacing.xs),
          Text('本季动画与放送日程', style: Theme.of(context).textTheme.bodyLarge),
          if (_staleBanners(context).isNotEmpty) ...<Widget>[
            const SizedBox(height: MioSpacing.md),
            for (final banner in _staleBanners(context)) banner,
          ],
        ],
      ),
    );
  }

  List<Widget> _staleBanners(BuildContext context) {
    final banners = <Widget>[];
    void add<T>(HomeSection<T> section) {
      if (!section.isStale) return;
      final failure = section.refreshFailure;
      final message = failure == null
          ? '正在更新缓存内容…'
          : '当前显示离线缓存，内容更新时间：${_formatTime(section.fetchedAt)}';
      banners.add(
        _InlineNotice(
          message: message,
          onRetry: failure == null ? null : onRetry,
        ),
      );
    }

    add(snapshot.catalog);
    add(snapshot.schedule);
    return banners;
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '未知';
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: MioSpacing.xs),
      padding: const EdgeInsets.all(MioSpacing.sm),
      decoration: BoxDecoration(
        color: MioColors.surfaceHigh,
        borderRadius: BorderRadius.circular(MioRadii.sm),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('重试更新')),
        ],
      ),
    );
  }
}

class _HeroCarouselSection extends ConsumerStatefulWidget {
  const _HeroCarouselSection({required this.hero, required this.status});

  final List<AnimeSummary> hero;
  final HomeSectionStatus status;

  @override
  ConsumerState<_HeroCarouselSection> createState() =>
      _HeroCarouselSectionState();
}

class _HeroCarouselSectionState extends ConsumerState<_HeroCarouselSection> {
  static const Duration _autoAdvance = Duration(seconds: 5);

  final HeroImagePrefetcher _prefetcher = HeroImagePrefetcher();
  final PageController _controller = PageController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _current = 0;
  bool _userPaused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_syncTimer);
    _prefetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
    _prefetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _prefetcher.clear();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _shouldAutoPlay {
    if (_userPaused || _focusNode.hasFocus) return false;
    if (widget.hero.length < 2) return false;
    if (MediaQuery.disableAnimationsOf(context)) return false;
    if (!TickerMode.valuesOf(context).enabled) return false;
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (!_shouldAutoPlay) return;
    _timer = Timer.periodic(_autoAdvance, (_) {
      if (!mounted || !_shouldAutoPlay) return;
      _advance();
    });
  }

  void _advance() {
    final next = (_current + 1) % widget.hero.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _prefetch() {
    _prefetcher.prefetch(
      request: (uri) => ref.read(imageBytesProvider(uri)),
      items: widget.hero,
      current: _current,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == HomeSectionStatus.failed) {
      return const SizedBox.shrink();
    }
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= MioBreakpoints.expanded;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: wide ? 360 : 280,
            child: Focus(
              focusNode: _focusNode,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.hero.length,
                onPageChanged: (index) {
                  setState(() => _current = index);
                  _prefetch();
                },
                itemBuilder: (context, index) {
                  return _HeroSlide(
                    anime: widget.hero[index],
                    onTap: () {
                      unawaited(
                        AnimeDetailRouteData(
                          id: widget.hero[index].id.value,
                        ).push<void>(context),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: MioSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (var index = 0; index < widget.hero.length; index += 1)
                _Dot(
                  active: index == _current,
                  onTap: () {
                    setState(() => _current = index);
                    _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              const SizedBox(width: MioSpacing.md),
              IconButton(
                tooltip: _userPaused ? '继续自动播放' : '暂停自动播放',
                onPressed: () {
                  setState(() {
                    _userPaused = !_userPaused;
                    _syncTimer();
                  });
                },
                icon: Icon(
                  _userPaused ? Icons.play_arrow : Icons.pause,
                  semanticLabel: _userPaused ? '继续' : '暂停',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({required this.anime, required this.onTap});

  final AnimeSummary anime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: MioColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            MioImage(imageUrl: anime.imageUrl, semanticLabel: '$title 海报'),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Color(0xB3000000)],
                ),
              ),
            ),
            Positioned(
              left: MioSpacing.lg,
              right: MioSpacing.lg,
              bottom: MioSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: MioColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: MioSpacing.xs),
                  Wrap(
                    spacing: MioSpacing.sm,
                    children: <Widget>[
                      if (anime.score case final score?)
                        Text('★ ${score.toStringAsFixed(1)}'),
                      Text(anime.sourceLabel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? '当前轮播页' : '切换到该轮播页',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: MioDurations.short,
          width: active ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? MioColors.accent : MioColors.outline,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _CatalogSections extends StatelessWidget {
  const _CatalogSections({required this.snapshot, required this.onRetry});

  final HomeSnapshot snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _PartitionBody<HomeCatalogContent>(
      section: snapshot.catalog,
      onRetry: onRetry,
      builder: (context, content) {
        final wide =
            MediaQuery.sizeOf(context).width >= MioBreakpoints.expanded;
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SectionHeader(title: '本季推荐', subtitle: '按评分排序的本季动画'),
            SizedBox(
              height: largeText ? 340 : 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
                itemCount: content.recommended.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: MioSpacing.md),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: wide ? 210 : 180,
                    child: AnimeCatalogCard(anime: content.recommended[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: MioSpacing.xl),
            _SectionHeader(title: '热门动画', subtitle: '按追番热度排序'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = wide
                      ? 4
                      : constraints.maxWidth >= MioBreakpoints.medium
                      ? 3
                      : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: MioSpacing.md,
                      crossAxisSpacing: MioSpacing.md,
                      mainAxisExtent: largeText ? 440 : 300,
                    ),
                    itemCount: content.trending.length,
                    itemBuilder: (context, index) {
                      return AnimeCatalogCard(anime: content.trending[index]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScheduleSections extends StatelessWidget {
  const _ScheduleSections({required this.snapshot, required this.onRetry});

  final HomeSnapshot snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _PartitionBody<HomeScheduleContent>(
      section: snapshot.schedule,
      onRetry: onRetry,
      builder: (context, content) {
        final wide =
            MediaQuery.sizeOf(context).width >= MioBreakpoints.expanded;
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: MioSpacing.xl),
            _SectionHeader(title: '最近更新', subtitle: '接下来放送的动画'),
            SizedBox(
              height: largeText ? 144 : 96,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
                itemCount: content.recent.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: MioSpacing.md),
                itemBuilder: (context, index) {
                  final item = content.recent[index];
                  return _RecentTile(item: item);
                },
              ),
            ),
            const SizedBox(height: MioSpacing.xl),
            _SectionHeader(title: '放送预览', subtitle: '本周七天放送计划'),
            if (wide)
              _WeekStrip(days: content.days, largeText: largeText)
            else
              _TodayPreview(days: content.days),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MioSpacing.lg,
                MioSpacing.md,
                MioSpacing.lg,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    ScheduleRouteData().go(context);
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('查看完整日程'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PartitionBody<T> extends StatelessWidget {
  const _PartitionBody({
    required this.section,
    required this.onRetry,
    required this.builder,
  });

  final HomeSection<T> section;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context, T value) builder;

  @override
  Widget build(BuildContext context) {
    return switch (section.status) {
      HomeSectionStatus.loading => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MioSpacing.lg,
          vertical: MioSpacing.xl,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      HomeSectionStatus.failed => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MioSpacing.lg,
          vertical: MioSpacing.xl,
        ),
        child: MioStateView.failure(
          failure: section.failure ?? const UnknownFailure(),
          onRetry: onRetry,
        ),
      ),
      HomeSectionStatus.ready => builder(context, section.value as T),
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MioSpacing.lg,
        0,
        MioSpacing.lg,
        MioSpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: MioSpacing.xxs),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final anime = item.anime;
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return Card(
      color: MioColors.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          unawaited(
            AnimeDetailRouteData(id: anime.id.value).push<void>(context),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: MioSpacing.md),
          child: Row(
            children: <Widget>[
              Text(
                item.timed ? item.airTime!.text : '待定',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: item.timed
                      ? MioColors.accent
                      : MioColors.textSecondary,
                ),
              ),
              const SizedBox(width: MioSpacing.md),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayPreview extends StatelessWidget {
  const _TodayPreview({required this.days});

  final List<ScheduleDay> days;

  @override
  Widget build(BuildContext context) {
    final today =
        days.where((day) => day.isToday).firstOrNull ?? days.firstOrNull;
    if (today == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
      child: Card(
        color: MioColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(MioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(today.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: MioSpacing.sm),
              if (today.items.isEmpty)
                Text('今日暂无已知放送', style: Theme.of(context).textTheme.bodyMedium)
              else
                for (final item in today.items.take(5)) _PreviewRow(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days, required this.largeText});

  final List<ScheduleDay> days;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: largeText ? 340 : 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: MioSpacing.md),
        itemBuilder: (context, index) {
          final day = days[index];
          return SizedBox(
            width: 170,
            child: Card(
              color: day.isToday ? MioColors.surfaceHigh : MioColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(MioSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(day.label),
                    const SizedBox(height: MioSpacing.xs),
                    Expanded(
                      child: day.items.isEmpty
                          ? Text(
                              '暂无安排',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : ListView.separated(
                              itemCount: day.items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: MioSpacing.xxs),
                              itemBuilder: (context, itemIndex) {
                                return _PreviewRow(item: day.items[itemIndex]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.item});

  final ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    final title = item.anime.title.isEmpty ? '标题暂缺' : item.anime.title;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MioSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 44,
            child: Text(
              item.timed ? item.airTime!.text : '待定',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: item.timed ? MioColors.accent : MioColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: MioSpacing.xs),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
