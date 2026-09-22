import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/presentation/hero_prefetch.dart';
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
                  child: _HeroLouverSection(
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
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'MioAni',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
              ),
              const _ScheduleShortcut(),
            ],
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

/// Jumps to the schedule branch, mirroring the hero shortcut in the reference
/// home layout.
class _ScheduleShortcut extends StatelessWidget {
  const _ScheduleShortcut();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => ScheduleRouteData().go(context),
      style: TextButton.styleFrom(foregroundColor: MioColors.accent),
      icon: const Icon(Icons.calendar_month),
      label: const Text('新番时间表'),
    );
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

/// Louver ("百叶窗") hero: one fanned-out poster whose neighbours stay visible as
/// narrow slats on both sides.
class _HeroLouverSection extends ConsumerStatefulWidget {
  const _HeroLouverSection({required this.hero, required this.status});

  final List<AnimeSummary> hero;
  final HomeSectionStatus status;

  @override
  ConsumerState<_HeroLouverSection> createState() => _HeroLouverSectionState();
}

class _HeroLouverSectionState extends ConsumerState<_HeroLouverSection> {
  static const Duration _autoAdvance = Duration(seconds: 5);

  /// Heroes live inside a long looping page list: every position then keeps a
  /// slat on both sides, and auto-advance walks forward instead of rewinding
  /// across the whole strip on wrap-around.
  static const int _loopOrigin = 1000;

  final HeroImagePrefetcher _prefetcher = HeroImagePrefetcher();
  final FocusNode _focusNode = FocusNode();
  PageController _controller = PageController();
  double? _controllerFraction;
  Timer? _timer;
  int _current = 0;

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
    if (_focusNode.hasFocus) return false;
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
    final page = _controller.page;
    if (page == null) return;
    _controller.animateToPage(
      page.round() + 1,
      duration: MioDurations.long,
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

  /// The page slot follows the width the section actually receives, so the
  /// controller is replaced whenever that width turns into another slot
  /// fraction. The retired controller is still attached to the PageView of the
  /// frame being built, so it is released once that frame is done.
  PageController _controllerFor(_LouverMetrics metrics) {
    if (_controllerFraction == metrics.viewportFraction) return _controller;
    final previous = _controller;
    final page = previous.hasClients ? previous.page : null;
    _controller = PageController(
      initialPage: page?.round() ?? widget.hero.length * _loopOrigin,
      viewportFraction: metrics.viewportFraction,
    );
    _controllerFraction = metrics.viewportFraction;
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    return _controller;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == HomeSectionStatus.failed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: MioSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _LouverMetrics.forWidth(constraints.maxWidth);
          return Focus(
            focusNode: _focusNode,
            child: Center(
              child: SizedBox(
                width: metrics.pageWidth,
                height: metrics.cardHeight,
                child: PageView.builder(
                  controller: _controllerFor(metrics),
                  itemCount: widget.hero.length == 1 ? 1 : null,
                  onPageChanged: (index) {
                    setState(() => _current = index % widget.hero.length);
                    _prefetch();
                  },
                  itemBuilder: (context, index) {
                    final anime = widget.hero[index % widget.hero.length];
                    return _HeroSlide(
                      anime: anime,
                      innerPadding: metrics.innerPadding,
                      onTap: () {
                        unawaited(
                          AnimeDetailRouteData(
                            id: anime.id.value,
                          ).push<void>(context),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Size of the fanned-out card, the slats flanking it and the page slot the
/// carousel snaps to. Slat and gap stay proportional to the card, so the louver
/// keeps one silhouette from compact phones up to tablets; on wide windows the
/// whole strip is centred instead of stretching the card any further.
final class _LouverMetrics {
  const _LouverMetrics({
    required this.cardHeight,
    required this.innerPadding,
    required this.pageWidth,
    required this.viewportFraction,
  });

  factory _LouverMetrics.forWidth(double available) {
    final cardWidth = (available * _cardWidthFraction).clamp(
      _minimumCardWidth,
      _maximumCardWidth,
    );
    final gap = cardWidth * _gapRatio;
    final strip = cardWidth * (1 + 2 * _gapRatio + 2 * _slatRatio);
    final pageWidth = math.min(strip, available);
    return _LouverMetrics(
      cardHeight: cardWidth / _cardAspectRatio,
      innerPadding: gap / 2,
      pageWidth: pageWidth,
      viewportFraction: (cardWidth + gap) / pageWidth,
    );
  }

  /// Share of the window the fanned-out card takes.
  static const double _cardWidthFraction = 0.7;
  static const double _minimumCardWidth = 180;
  static const double _maximumCardWidth = 420;

  /// Visible neighbour slat and the gap between cards, both relative to the
  /// fanned-out card width.
  static const double _slatRatio = 0.19;
  static const double _gapRatio = 0.045;

  /// Card width over its height: the near-square silhouette of the reference
  /// louver.
  static const double _cardAspectRatio = 0.98;

  final double cardHeight;

  /// Space each side of a card inside its page slot, which is the half gap
  /// between two neighbouring cards.
  final double innerPadding;
  final double pageWidth;
  final double viewportFraction;
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({
    required this.anime,
    required this.innerPadding,
    required this.onTap,
  });

  final AnimeSummary anime;
  final double innerPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    final radius = BorderRadius.circular(MioRadii.lg);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: innerPadding),
      child: Semantics(
        button: true,
        label: '查看 $title 详情',
        child: Card(
          clipBehavior: Clip.antiAlias,
          color: MioColors.surface,
          shape: RoundedRectangleBorder(borderRadius: radius),
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                MioImage(
                  imageUrl: anime.imageUrl,
                  semanticLabel: '$title 海报',
                  borderRadius: MioRadii.lg,
                ),
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
                  left: MioSpacing.md,
                  right: MioSpacing.md,
                  bottom: MioSpacing.md,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: MioColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _SectionHeader(title: '本季推荐', subtitle: '按追番热度排序'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
              child: _PosterGrid(items: content.trending),
            ),
          ],
        );
      },
    );
  }
}

/// Portrait poster grid: three posters per row on phones, denser on wider
/// windows, the way season posters are published.
///
/// Every tile reserves the same poster height and the same text height, so a
/// row reads as one band: the poster is never squeezed by a longer neighbour
/// title, and the row is as tall as its tallest card.
class _PosterGrid extends StatelessWidget {
  const _PosterGrid({required this.items});

  final List<AnimeSummary> items;

  /// Poster art is published in portrait, unlike the hero slats.
  static const double _posterAspectRatio = 2 / 3;

  /// Title and meta lines reserved on every tile, whatever the title length.
  static const int _titleLines = 2;
  static const int _metaLines = 1;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final metaStyle = Theme.of(context).textTheme.bodySmall;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (MioBreakpoints.windowClassFor(
          constraints.maxWidth,
        )) {
          MioWindowClass.compact => 3,
          MioWindowClass.medium => 4,
          MioWindowClass.expanded => 6,
        };
        final tileWidth =
            (constraints.maxWidth - (columns - 1) * MioSpacing.md) / columns;
        // Measured against the tile width, so the reserved blocks match the
        // painted text at every text scale and never overflow the tile.
        final titleBlock = _textBlockHeight(
          textScaler: textScaler,
          style: titleStyle,
          lines: _titleLines,
          maxWidth: tileWidth,
        );
        final metaBlock = _textBlockHeight(
          textScaler: textScaler,
          style: metaStyle,
          lines: _metaLines,
          maxWidth: tileWidth,
        );
        final posterHeight = tileWidth / _posterAspectRatio;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: MioSpacing.md,
            crossAxisSpacing: MioSpacing.md,
            mainAxisExtent:
                posterHeight +
                MioSpacing.xs +
                titleBlock +
                MioSpacing.xxs +
                metaBlock,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _PosterCard(
            anime: items[index],
            posterHeight: posterHeight,
            titleBlock: titleBlock,
            metaBlock: metaBlock,
          ),
        );
      },
    );
  }

  static double _textBlockHeight({
    required TextScaler textScaler,
    required TextStyle? style,
    required int lines,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: '最长的动画标题' * 4, style: style),
      maxLines: lines,
      textScaler: textScaler,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.anime,
    required this.posterHeight,
    required this.titleBlock,
    required this.metaBlock,
  });

  final AnimeSummary anime;
  final double posterHeight;
  final double titleBlock;
  final double metaBlock;

  @override
  Widget build(BuildContext context) {
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    final meta = <String>[
      if (anime.score case final score?) '★ ${score.toStringAsFixed(1)}',
      anime.sourceLabel,
    ].join(' · ');
    return Semantics(
      button: true,
      label: '查看 $title 详情',
      child: InkWell(
        onTap: () {
          unawaited(
            AnimeDetailRouteData(id: anime.id.value).push<void>(context),
          );
        },
        borderRadius: BorderRadius.circular(MioRadii.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // The poster absorbs the sub-pixel slack of the grid extent, so
            // rounding never pushes the text out of the tile; every poster in
            // the row still gets the same height out of the same extent.
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: MioImage(
                  imageUrl: anime.imageUrl,
                  semanticLabel: '$title 海报',
                ),
              ),
            ),
            const SizedBox(height: MioSpacing.xs),
            SizedBox(
              height: titleBlock,
              child: Text(
                title,
                maxLines: _PosterGrid._titleLines,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: MioSpacing.xxs),
            SizedBox(
              height: metaBlock,
              child: Text(
                meta,
                maxLines: _PosterGrid._metaLines,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
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
