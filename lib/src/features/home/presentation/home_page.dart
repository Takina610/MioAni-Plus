import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/anime_detail_navigation.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_cover_flight.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/presentation/hero_louver.dart';
import 'package:mio_ani/src/features/home/presentation/hero_prefetch.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
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
      // The brand backdrop belongs to the shell, behind every branch.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _requestRefresh(ref);
            await ref.read(homeStreamProvider.future);
          },
          child: CustomScrollView(
            key: pageStorageKey,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: _HomeHeader()),
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
              const _ExploreSection(),
              const SliverToBoxAdapter(child: SizedBox(height: MioSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  /// A pull on the page is one gesture from the user, so everything on it is
  /// read again: the season grid, the explore ranking behind it, and the
  /// posters themselves.
  void _requestRefresh(WidgetRef ref) {
    ref.read(homeControllerProvider.notifier).refresh();
    ref.read(homeExploreControllerProvider.notifier).refresh();
    // A cover whose download failed is only asked for again when its tile is
    // built afresh, which a reader has no way to do from here. Dropping the
    // image providers re-reads every poster on screen: one this run has already
    // read is answered from the in-memory covers, so this costs a frame and not
    // a download, and it is the only way a failed cover gets another try.
    ref.invalidate(imageBytesProvider);
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

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
        ],
      ),
    );
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
            TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

/// Louver ("百叶窗") hero: one fanned-out poster whose neighbours stay visible as
/// narrow slats on both sides, the way the reference home carousel draws them.
class _HeroLouverSection extends ConsumerStatefulWidget {
  const _HeroLouverSection({required this.hero, required this.status});

  final List<AnimeSummary> hero;
  final HomeSectionStatus status;

  @override
  ConsumerState<_HeroLouverSection> createState() => _HeroLouverSectionState();
}

class _HeroLouverSectionState extends ConsumerState<_HeroLouverSection>
    with SingleTickerProviderStateMixin {
  /// Dwell between two slides, as in the reference carousel. It is measured
  /// from the end of the last scroll, so a swipe never cuts the next one short.
  static const Duration _autoAdvance = Duration(seconds: 3);

  /// Slides per second a flick has to carry to count as one the user meant,
  /// rather than a nudge that settles back where it started.
  static const double _decisiveFlick = 2;

  /// Slides the strip keeps laid out around the centred one. Two each way
  /// covers the widest reach of a slide that is still on the strip.
  static const int _laidOutAround = 2;

  final HeroImagePrefetcher _prefetcher = HeroImagePrefetcher();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _settle = AnimationController.unbounded(
    vsync: this,
  );
  Timer? _timer;
  double _page = 0;
  HeroLouverMetrics? _metrics;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _settle.addListener(_followSettle);
    _focusNode.addListener(_restartAutoAdvance);
    _prefetch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartAutoAdvance();
    _prefetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _prefetcher.clear();
    // The section can be torn down mid-slide, when the branch changes or the
    // snapshot goes away. Stopping first cancels the settle's future, so it
    // cannot come back to arm a dwell on a section that is gone.
    _settle.stop();
    _settle.dispose();
    _focusNode.dispose();
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

  /// Arms the dwell up to the next slide, replacing one already running.
  void _restartAutoAdvance() {
    _timer?.cancel();
    _timer = null;
    if (!_shouldAutoPlay) return;
    _timer = Timer(_autoAdvance, _advanceIfDue);
  }

  /// Holds the louver still while it is moving, the way the reference carousel
  /// does: no dwell runs while a finger is down or a slide is still settling.
  void _pauseAutoAdvance() {
    _timer?.cancel();
    _timer = null;
  }

  void _advanceIfDue() {
    if (!mounted || !_shouldAutoPlay) return;
    _settleOn(_roundedPage + 1);
  }

  /// Carries the strip to [target], a whole slide, and arms the next dwell once
  /// it gets there.
  ///
  /// The animation runs on the strip's own position, so a settle that starts
  /// from a half-dragged strip carries on from there rather than from wherever
  /// the last one left off.
  void _settleOn(int target) {
    _settle.value = _page;
    _settle
        .animateTo(
          target.toDouble(),
          duration: MioMotion.resolve(context, MioDurations.long),
          curve: Curves.easeOutCubic,
        )
        .whenComplete(() {
          if (mounted) _restartAutoAdvance();
        });
  }

  /// Draws every frame of the settle, so the strip slides rather than jumps.
  void _followSettle() {
    if (!mounted) return;
    _moveTo(_settle.value);
  }

  void _moveTo(double page) {
    final previous = _roundedPage;
    setState(() => _page = page);
    if (_roundedPage != previous) {
      _current = _indexOf(_roundedPage);
      _prefetch();
    }
  }

  int get _roundedPage => _page.round();

  int _indexOf(int page) {
    final length = widget.hero.length;
    return ((page % length) + length) % length;
  }

  void _startDrag(DragStartDetails details) {
    _pauseAutoAdvance();
    _settle.stop();
  }

  void _dragBy(DragUpdateDetails details) {
    final metrics = _metrics;
    if (metrics == null) return;
    _moveTo(_page - details.delta.dx / metrics.sliceSpacing);
  }

  /// Settles on whichever slide the strip is closest to once the finger lifts.
  /// A flick decisive enough to mean it carries the strip half a slide further
  /// before the rounding, so it always lands one on and never skips one.
  void _endDrag(DragEndDetails details) {
    final metrics = _metrics;
    if (metrics == null) return;
    final slidesPerSecond =
        -details.velocity.pixelsPerSecond.dx / metrics.sliceSpacing;
    final carried = slidesPerSecond.abs() >= _decisiveFlick
        ? slidesPerSecond.sign * 0.5
        : 0.0;
    _settleOn((_page + carried).round());
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
    // No bottom gap of its own: the heading below carries the section break, so
    // the hero, the season grid and the explore feed all break at one line.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = HeroLouverMetrics.forWidth(constraints.maxWidth);
          // The drag handlers need the strip's own measurements, so the strip
          // leaves them here rather than measuring itself again.
          _metrics = metrics;
          return Focus(
            focusNode: _focusNode,
            child: Center(
              child: Semantics(
                onScrollLeft: () => _settleOn(_roundedPage - 1),
                onScrollRight: () => _settleOn(_roundedPage + 1),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _startDrag,
                  onHorizontalDragUpdate: _dragBy,
                  onHorizontalDragEnd: _endDrag,
                  child: SizedBox(
                    key: heroStripKey,
                    width: metrics.pageWidth,
                    height: metrics.cardHeight,
                    child: Stack(
                      children: <Widget>[
                        for (final index in _laidOutSlides)
                          _slide(context, metrics, index),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The slides the strip keeps on it: the centred one, and [_laidOutAround]
  /// each way, so a slide that has been pushed aside is still laid out and can
  /// be drawn for as long as any part of it is on the strip.
  Iterable<int> get _laidOutSlides sync* {
    final centre = _roundedPage;
    for (var offset = -_laidOutAround; offset <= _laidOutAround; offset += 1) {
      yield centre + offset;
    }
  }

  Widget _slide(BuildContext context, HeroLouverMetrics metrics, int index) {
    final anime = widget.hero[_indexOf(index)];
    final distance = index - _page;
    // The picture the strip is offering, which is the one a tap on this slide
    // sends to the detail page.
    final cover = AnimeCoverFlight.cover(
      anime: anime,
      place: AnimeCoverPlace.homeHero,
    );
    return Positioned(
      // A window is the middle of its card, so putting the window's centre on
      // the slide's slice puts the card where the strip wants it.
      left: metrics.windowCenterFor(distance) - metrics.cardWidth / 2,
      top: 0,
      width: metrics.cardWidth,
      height: metrics.cardHeight,
      child: ExcludeSemantics(
        // Only slides still showing a slat are on offer; one the strip has
        // pushed clear of itself is decoration and not for assistive
        // technology to reach.
        excluding: metrics.focusFor(distance) == 0,
        child: ClipRRect(
          clipper: HeroWindowClipper(
            windowWidth: metrics.windowWidthFor(distance),
            radius: MioRadii.lg,
          ),
          child: _HeroCard(
            poster: _HeroPoster(anime: anime, cover: cover),
            title: anime.title.isEmpty ? '标题暂缺' : anime.title,
            focus: metrics.focusFor(distance),
            onTap: () => openAnimeDetail(context, ref, anime, cover: cover),
          ),
        ),
      ),
    );
  }
}

/// Poster art and scrim of a hero card, drawn at the full card size the way the
/// reference carousel composes every item.
class _HeroPoster extends StatelessWidget {
  const _HeroPoster({required this.anime, required this.cover});

  final AnimeSummary anime;

  /// The work's picture as this strip is showing it, which is also the picture
  /// a tap on this slide flies to the detail page.
  final AnimeCoverFlight cover;

  /// Scrim of the reference carousel: the art stays clean down to the middle,
  /// then darkens under the title.
  static const Color _scrim = Color(0x9C000000);

  @override
  Widget build(BuildContext context) {
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimeCoverSource(flight: cover, semanticLabel: '$title 海报'),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[Colors.transparent, Colors.transparent, _scrim],
            ),
          ),
        ),
      ],
    );
  }
}

/// The card a hero slide shows through its window: the poster under the title
/// the centred card carries.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.poster,
    required this.title,
    required this.focus,
    required this.onTap,
  });

  final Widget poster;
  final String title;

  /// Share of the window that is open on this card; the title rides with it, so
  /// a slat never shows a fragment of a title cut off by its window.
  final double focus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '查看 $title 详情',
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: MioColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MioRadii.lg),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              poster,
              Positioned(
                left: MioSpacing.md,
                right: MioSpacing.md,
                bottom: MioSpacing.md,
                child: Opacity(
                  opacity: focus,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
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
    return switch (snapshot.catalog.status) {
      // The season grid says what it is before it has anything to show: the
      // heading is already known, and the tiles are the shape the posters will
      // take, so the page is a page from the first frame rather than a spinner
      // and then a jump.
      HomeSectionStatus.loading => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionHeader(title: '本季推荐', subtitle: '按追番热度排序'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: MioSpacing.lg),
            child: _PosterGrid.loading(),
          ),
        ],
      ),
      HomeSectionStatus.failed => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MioSpacing.lg,
          vertical: MioSpacing.xl,
        ),
        child: MioStateView.failure(
          failure: snapshot.catalog.failure ?? const UnknownFailure(),
          onRetry: onRetry,
        ),
      ),
      HomeSectionStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(title: '本季推荐', subtitle: '按追番热度排序'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
            child: switch ((snapshot.catalog.value as HomeCatalogContent)
                .trending) {
              // A season with nothing in it is not a season still being read:
              // it says so rather than standing empty tiles up forever.
              final trending when trending.isEmpty => const _SectionEmpty(
                message: '本季暂无可推荐的作品',
              ),
              final trending => _PosterGrid(items: trending),
            },
          ),
        ],
      ),
    };
  }
}

/// One quiet line where a section would have had its content.
class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MioSpacing.lg),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

/// Portrait poster grid: three posters per row on phones, denser on wider
/// windows, the way season posters are published.
///
/// A grid that is still being read draws [_skeletonRows] rows of poster-shaped
/// blocks instead, which is how a section keeps the page's layout while its
/// content is on the way.
class _PosterGrid extends StatelessWidget {
  const _PosterGrid({required this.items}) : loading = false;

  /// The grid of a section whose posters have not arrived.
  const _PosterGrid.loading() : items = const <AnimeSummary>[], loading = true;

  final List<AnimeSummary> items;
  final bool loading;

  /// Rows of poster blocks a waiting grid stands for.
  static const int _skeletonRows = 2;

  /// Where this grid's tiles stand. The feed below it draws the same tiles, and
  /// the two can be showing one work at once, so a tap has to say which of them
  /// the reader was looking at — see [AnimeCoverPlace].
  static const String _place = AnimeCoverPlace.homeSeason;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _PosterGridMetrics.of(context, constraints.maxWidth);
        final placeholderCount = loading
            ? metrics.delegate.crossAxisCount * _skeletonRows
            : 0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: metrics.delegate,
          itemCount: items.length + placeholderCount,
          itemBuilder: (context, index) => index < items.length
              ? _PosterCard(
                  anime: items[index],
                  metrics: metrics,
                  place: _place,
                )
              : _PosterPlaceholder(metrics: metrics),
        );
      },
    );
  }
}

/// Geometry of one poster tile, shared by the season grid and the explore grid
/// so both sections lay their posters out identically.
///
/// Every tile reserves the same poster height and the same text height, so a
/// row reads as one band: the poster is never squeezed by a longer neighbour
/// title, and the row is as tall as its tallest card.
final class _PosterGridMetrics {
  const _PosterGridMetrics({
    required this.posterHeight,
    required this.titleBlock,
    required this.metaBlock,
    required this.delegate,
  });

  /// Poster art is published in portrait, unlike the hero slats.
  static const double _posterAspectRatio = 2 / 3;

  /// Title and meta lines reserved on every tile, whatever the title length.
  static const int titleLines = 2;
  static const int metaLines = 1;

  /// Narrowest width the tiles are ever measured against: three of the
  /// smallest compact tiles and the gaps between them.
  static const double _minimumGridWidth =
      3 * _minimumTileWidth + 2 * MioSpacing.md;
  static const double _minimumTileWidth = 64;

  /// Resolves the geometry for a grid [maxWidth] wide, which is the width the
  /// tiles get — callers pass the width left inside the page padding.
  factory _PosterGridMetrics.of(BuildContext context, double maxWidth) {
    // A grid can be asked to lay out before the window it is in has a size —
    // the first frame of a cold start, a window being dragged narrow. A tile
    // cannot be divided out of nothing, and a negative tile would assert inside
    // the text measurement below, so the geometry is resolved against a floor.
    // Whatever is drawn in that state is off screen anyway.
    final width = math.max(maxWidth, _minimumGridWidth);
    final textScaler = MediaQuery.textScalerOf(context);
    final columns = switch (MioBreakpoints.windowClassFor(width)) {
      MioWindowClass.compact => 3,
      MioWindowClass.medium => 4,
      MioWindowClass.expanded => 6,
    };
    final tileWidth = (width - (columns - 1) * MioSpacing.md) / columns;
    // Measured against the tile width, so the reserved blocks match the
    // painted text at every text scale and never overflow the tile.
    final titleBlock = _textBlockHeight(
      textScaler: textScaler,
      style: Theme.of(context).textTheme.titleMedium,
      lines: titleLines,
      maxWidth: tileWidth,
    );
    final metaBlock = _textBlockHeight(
      textScaler: textScaler,
      style: Theme.of(context).textTheme.bodySmall,
      lines: metaLines,
      maxWidth: tileWidth,
    );
    final posterHeight = tileWidth / _posterAspectRatio;
    return _PosterGridMetrics(
      posterHeight: posterHeight,
      titleBlock: titleBlock,
      metaBlock: metaBlock,
      delegate: SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  final double posterHeight;
  final double titleBlock;
  final double metaBlock;
  final SliverGridDelegateWithFixedCrossAxisCount delegate;

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

class _PosterCard extends ConsumerWidget {
  const _PosterCard({
    required this.anime,
    required this.metrics,
    required this.place,
  });

  final AnimeSummary anime;
  final _PosterGridMetrics metrics;

  /// Where the tile is standing, which is half of what its tag says.
  final String place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    final meta = <String>[
      if (anime.score case final score?) '★ ${score.toStringAsFixed(1)}',
      anime.sourceLabel,
    ].join(' · ');
    // The tile, not the hero: the picture a list draws is the rendition the
    // source publishes for lists, and it is the one a tap sends to the detail
    // page's poster.
    final cover = AnimeCoverFlight.tile(anime: anime, place: place);
    return Semantics(
      button: true,
      label: '查看 $title 详情',
      child: InkWell(
        onTap: () => openAnimeDetail(context, ref, anime, cover: cover),
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
                child: AnimeCoverSource(
                  flight: cover,
                  semanticLabel: '$title 海报',
                ),
              ),
            ),
            const SizedBox(height: MioSpacing.xs),
            SizedBox(
              height: metrics.titleBlock,
              child: Text(
                title,
                maxLines: _PosterGridMetrics.titleLines,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: MioSpacing.xxs),
            SizedBox(
              height: metrics.metaBlock,
              child: Text(
                meta,
                maxLines: _PosterGridMetrics.metaLines,
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

/// A tile of the season grid before its poster is known: the same poster box
/// and the same reserved lines, so the grid does not move when the real titles
/// land in it.
class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.metrics});

  final _PosterGridMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: MioPlaceholder(height: metrics.posterHeight),
          ),
        ),
        const SizedBox(height: MioSpacing.xs),
        SizedBox(
          height: metrics.titleBlock,
          child: const MioPlaceholder(
            width: double.infinity,
            radius: MioRadii.sm,
          ),
        ),
        const SizedBox(height: MioSpacing.xxs),
        SizedBox(
          height: metrics.metaBlock,
          child: const MioPlaceholder(width: 64, radius: MioRadii.sm),
        ),
      ],
    );
  }
}

/// The explore feed: the source-wide popularity ranking, pulled in one page at
/// a time as the reader reaches the end of what is loaded.
///
/// The section names itself in every state. It sits far below the season grid,
/// so a bare spinner or failure block down there would leave the reader
/// guessing which part of the page it belongs to.
///
/// It is also where the feed is grown, because it is the only part of the page
/// that knows both the ranking's state and how far the page has been scrolled:
/// the page's own [ScrollPosition] is the nearest one above this sliver, so a
/// measurement taken here is about the home page and not about the grids
/// nested inside it.
class _ExploreSection extends ConsumerStatefulWidget {
  const _ExploreSection();

  @override
  ConsumerState<_ExploreSection> createState() => _ExploreSectionState();
}

class _ExploreSectionState extends ConsumerState<_ExploreSection> {
  ScrollPosition? _position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.of(context).position;
    if (identical(position, _position)) return;
    _position?.removeListener(_readOnIfAtEnd);
    _position = position..addListener(_readOnIfAtEnd);
  }

  @override
  void dispose() {
    _position?.removeListener(_readOnIfAtEnd);
    super.dispose();
  }

  /// Asks for the next page once the reader is within a viewport of the end of
  /// what is loaded.
  ///
  /// A scroll moves the position and calls this; content that only *grew*
  /// leaves the position still, which is why every build checks again after the
  /// frame — that is how a feed shorter than the viewport fills it without
  /// anyone scrolling. The check is a measurement either way. The feed used to
  /// be grown from its own tail instead, which is built whether or not it is on
  /// screen: the whole ranking, and every cover in it, arrived in one burst on
  /// the first frame.
  ///
  /// A page that failed is left alone here: it waits for the retry button, so
  /// scrolling past it cannot turn into a request storm.
  void _readOnIfAtEnd() {
    final position = _position;
    if (position == null || !position.hasContentDimensions) return;
    if (position.extentAfter > position.viewportDimension) return;
    final state = ref.read(homeExploreControllerProvider);
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.loadMoreFailure != null) {
      return;
    }
    ref.read(homeExploreControllerProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeExploreControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _readOnIfAtEnd();
    });
    return SliverMainAxisGroup(
      slivers: <Widget>[
        const SliverToBoxAdapter(
          child: _SectionHeader(title: '探索', subtitle: '全站热度排行，下滑继续'),
        ),
        ..._body(ref, state),
      ],
    );
  }

  List<Widget> _body(WidgetRef ref, HomeExploreState state) {
    if (state.isLoading) {
      // The grid the ranking will fill, standing empty: the section takes its
      // shape from the first frame, so nothing on the page moves when the first
      // page of the ranking arrives.
      return const <Widget>[
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: MioSpacing.lg),
          sliver: SliverToBoxAdapter(child: _PosterGrid.loading()),
        ),
        SliverToBoxAdapter(child: _ExploreFooter()),
      ];
    }
    if (state.status == HomeExploreStatus.failed) {
      return <Widget>[
        SliverToBoxAdapter(
          child: _ExploreNotice(
            message: state.failure?.userMessage ?? '探索内容暂时无法加载',
            onRetry: () =>
                ref.read(homeExploreControllerProvider.notifier).refresh(),
          ),
        ),
      ];
    }
    if (!state.hasContent) {
      return const <Widget>[
        SliverToBoxAdapter(child: _ExploreNotice(message: '暂时没有可探索的作品')),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final metrics = _PosterGridMetrics.of(
              context,
              constraints.crossAxisExtent,
            );
            // A page on its way is one more row of the grid, drawn as the
            // posters it will be: the feed grows into place rather than ending
            // in a spinner.
            final pending = state.isLoadingMore
                ? metrics.delegate.crossAxisCount
                : 0;
            return SliverGrid(
              gridDelegate: metrics.delegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) => index < state.items.length
                    ? _PosterCard(
                        anime: state.items[index],
                        metrics: metrics,
                        place: AnimeCoverPlace.homeExplore,
                      )
                    : _PosterPlaceholder(metrics: metrics),
                childCount: state.items.length + pending,
              ),
            );
          },
        ),
      ),
      const SliverToBoxAdapter(child: _ExploreFooter()),
    ];
  }
}

/// Quiet state of the explore section: a failure that left the feed with
/// nothing to show, and the way to ask again. It narrates what happened to the
/// request, not what the app is doing with its cache — a reader has no use for
/// the latter and never sees it.
class _ExploreNotice extends StatelessWidget {
  const _ExploreNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
      child: _InlineNotice(message: message, onRetry: onRetry),
    );
  }
}

/// Tail of the explore feed.
///
/// It reports where the feed stands and offers the retry a failed page waits
/// for; asking for the next page belongs to `_ExploreSection`, which can
/// measure the page it sits in rather than assume it has been reached. A page
/// on its way is drawn by the grid as the row of posters it will be, so this
/// has nothing to say about it beyond the line that names it.
class _ExploreFooter extends ConsumerWidget {
  const _ExploreFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeExploreControllerProvider);
    void load() => ref.read(homeExploreControllerProvider.notifier).loadMore();
    if (state.loadMoreFailure != null) {
      return Center(
        child: TextButton.icon(
          onPressed: load,
          icon: const Icon(Icons.refresh),
          label: const Text('加载更多失败，重试'),
        ),
      );
    }
    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.only(top: MioSpacing.lg),
        child: Center(
          child: Text('正在加载更多…', style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: MioSpacing.lg),
        child: Center(
          child: Text(
            '已显示全部 ${state.items.length} 部作品',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    // The next page is already on its way as the reader arrives here; this
    // stays tappable for the case where the trigger did not fire.
    return Center(
      child: TextButton.icon(
        onPressed: load,
        icon: const Icon(Icons.expand_more),
        label: const Text('加载更多'),
      ),
    );
  }
}

/// Heading of one home section.
///
/// The space above a heading belongs to the heading rather than to whatever
/// precedes it, so the hero, the season grid and the explore feed all break at
/// the same line. Leaving that gap to the section above is how the explore feed
/// ended up starting flush against the season grid.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MioSpacing.lg,
        MioSpacing.xl,
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
