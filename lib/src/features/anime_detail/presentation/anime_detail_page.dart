import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_preview_store.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_header.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_meta_board.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_sections.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_style.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/shared/design_system/mio_backdrop.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// The page about one anime.
///
/// It is one column: the work's art behind its own head, the record of it
/// beside or under that, and the sections under both. The head draws in two
/// passes rather than one — the list a reader tapped through left what it knew
/// in [AnimePreviewStore], so the art, the names and the opening of the summary
/// are on screen before the subject request has answered, and the pieces only
/// that request can fill are laid out as blocks of the shape they will take and
/// filled in place. Nothing here spins, and nothing here announces itself: a
/// reader who tapped a poster gets a page, and the page completes.
class AnimeDetailPage extends ConsumerWidget {
  const AnimeDetailPage({required this.sourceId, super.key});

  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = AnimeSourceId.tryParse(sourceId);
    return _DetailScaffold(
      child: switch (id) {
        null => MioStateView.notFound(message: '无法识别动画 ID：$sourceId'),
        final id when id.source != AnimeSource.bangumi => MioStateView.notFound(
          message: '该来源的动画详情将在后续版本提供',
        ),
        final id =>
          ref
              .watch(animeDetailStreamProvider(id))
              .when(
                loading: () => _loading(ref, id),
                error: (error, _) => error is NotFoundFailure
                    ? MioStateView.notFound(message: 'Bangumi 中不存在该动画')
                    : MioStateView.failure(
                        failure: error is AppFailure
                            ? error
                            : const UnknownFailure(),
                        onRetry: () => _requestRefresh(ref, id),
                      ),
                // A page that has a detail to draw draws it. Whether it came off
                // the network this second or off the cache a while ago is not
                // something the reader is told about: a work a reader tapped is
                // a work about to be on screen, and how the app got there is the
                // app's own business.
                data: (snapshot) =>
                    _AnimeDetailView(anime: snapshot.value, complete: true),
              ),
      },
    );
  }

  /// What to draw while the subject request is in flight: the head the tapped
  /// list already knew, or the shape of the page when nothing has seen this
  /// anime yet (a deep link, or a restored session).
  Widget _loading(WidgetRef ref, AnimeSourceId id) {
    final preview = ref.watch(animePreviewStoreProvider).lookup(id.value);
    return preview == null
        ? const _AnimeDetailSkeleton()
        : _AnimeDetailView(anime: preview, complete: false);
  }

  void _requestRefresh(WidgetRef ref, AnimeSourceId id) {
    final notifier = ref.read(detailRefreshGenerationProvider(id).notifier);
    notifier.state += 1;
  }
}

/// What every state of the page stands on: the brand canvas, and the way back
/// out of the page over it.
///
/// The page is opened over the shell rather than inside it, so it paints its
/// own canvas, and it keeps the canvas under the status bar: the art behind its
/// head runs to the top edge, and only the content is pushed clear of it. There
/// is no app bar for the same reason — the work's own name is the title here,
/// and a band of chrome would sit between the two.
class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MioBackdrop(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: child),
            const _BackButton(),
          ],
        ),
      ),
    );
  }
}

/// The way back, drawn over the art in the corner: the reference's glass pill,
/// as tall as a touch target is wide.
class _BackButton extends StatelessWidget {
  const _BackButton();

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: math.max(MioSpacing.sm, MediaQuery.paddingOf(context).top),
      left: MioSpacing.sm,
      child: Semantics(
        button: true,
        label: '返回',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: MioSpacing.sm),
              decoration: BoxDecoration(
                color: MioColors.surface.withValues(alpha: 0.62),
                border: Border.all(
                  color: MioColors.outline.withValues(alpha: 0.28),
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: MioColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '返回',
                    style: TextStyle(
                      color: MioColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The page once there is something to draw: the head, then the record and the
/// sections — beside each other on a window wide enough for two columns, one
/// under the other on a phone.
class _AnimeDetailView extends StatelessWidget {
  const _AnimeDetailView({required this.anime, required this.complete});

  /// The full detail once the subject request has answered, or the summary a
  /// list left behind while it has not.
  final AnimeSummary anime;

  /// Whether [anime] is the whole detail. While it is not, the pieces only the
  /// detail carries are drawn as the blocks they will fill.
  final bool complete;

  /// Gap between the record and the sections when they stand side by side, and
  /// between them when they are stacked.
  static const double _columnGap = 28;
  static const double _stackGap = MioSpacing.md;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final header = DetailHeaderMetrics.of(context, width);
        final windowClass = MioBreakpoints.windowClassFor(width);
        final sideBySide = windowClass != MioWindowClass.compact;
        final record = AnimeDetailMetaBoard(
          anime: anime,
          collapsible: !sideBySide,
        );
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: MioSizes.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AnimeDetailHeader(anime: anime, complete: complete),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: header.sidePadding,
                    ),
                    child: sideBySide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: windowClass == MioWindowClass.expanded
                                    ? 240
                                    : 200,
                                child: record,
                              ),
                              const SizedBox(width: _columnGap),
                              Expanded(
                                child: AnimeDetailSections(
                                  anime: anime,
                                  complete: complete,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              record,
                              const SizedBox(height: _stackGap),
                              AnimeDetailSections(
                                anime: anime,
                                complete: complete,
                              ),
                            ],
                          ),
                  ),
                  SizedBox(
                    height:
                        MioSpacing.xxl + MediaQuery.paddingOf(context).bottom,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The page before anything about it is known: the art band, the poster, the
/// title and the summary in the blocks the arrival will fill, then the record
/// and the tab bar waiting above the section that will land under them — so the
/// page has its shape from the first frame and nothing moves when it completes.
class _AnimeDetailSkeleton extends StatelessWidget {
  const _AnimeDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final header = DetailHeaderMetrics.of(context, width);
        final sideBySide =
            MioBreakpoints.windowClassFor(width) != MioWindowClass.compact;
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: MioSizes.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      header.sidePadding,
                      header.topPadding,
                      header.sidePadding,
                      MioSpacing.lg,
                    ),
                    child: _headSkeleton(context, header),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: header.sidePadding,
                    ),
                    child: sideBySide
                        ? const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(
                                width: 200,
                                child: _RecordSkeleton(count: 2),
                              ),
                              SizedBox(width: _AnimeDetailView._columnGap),
                              Expanded(child: _SectionsSkeleton()),
                            ],
                          )
                        : const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _RecordSkeleton(count: 0),
                              SizedBox(height: _AnimeDetailView._stackGap),
                              _SectionsSkeleton(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headSkeleton(BuildContext context, DetailHeaderMetrics header) {
    final title = MioPlaceholder(
      width: 240,
      height: header.titleSize,
      radius: MioRadii.sm,
    );
    final text = Column(
      crossAxisAlignment: header.stacked
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        const MioPlaceholder(width: 96, height: 12, radius: MioRadii.sm),
        const SizedBox(height: MioSpacing.sm),
        title,
        const SizedBox(height: MioSpacing.sm),
        const MioPlaceholder(width: 140, height: 14, radius: MioRadii.sm),
        const SizedBox(height: MioSpacing.md),
        const MioPlaceholderLines(lines: 4, lineHeight: 16),
      ],
    );
    final poster = MioPlaceholder(
      width: header.posterWidth,
      height: header.posterWidth * 1.5,
      radius: MioRadii.md,
    );
    if (!header.stacked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          poster,
          const SizedBox(width: MioSpacing.xl),
          Expanded(child: text),
        ],
      );
    }
    return Column(
      children: <Widget>[
        poster,
        const SizedBox(height: MioSpacing.xl),
        text,
      ],
    );
  }
}

/// The record's place while the subject is still being read: the score card and
/// a couple of facts, or — on a phone, where the record is one line — the line
/// itself. [count] is how many fact blocks stand under the card.
class _RecordSkeleton extends StatelessWidget {
  const _RecordSkeleton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const MioPlaceholder(height: 48, radius: MioRadii.md);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const MioPlaceholder(height: 62, radius: MioRadii.md),
        for (var index = 0; index < count; index += 1) ...<Widget>[
          const SizedBox(height: MioSpacing.sm),
          const MioPlaceholder(height: 58, radius: MioRadii.md),
        ],
      ],
    );
  }
}

/// The tab bar and the first section's worth of text while none of it is known.
class _SectionsSkeleton extends StatelessWidget {
  const _SectionsSkeleton();

  /// Height of the tab bar: a pill's own height inside the track's inset, so
  /// the bar that arrives lands in the space the block was holding.
  static const double _tabsHeight =
      DetailPillTabs.pillHeight + DetailPillTabs.inset * 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const MioPlaceholder(height: _tabsHeight, radius: MioRadii.md),
        const SizedBox(height: MioSpacing.lg),
        const MioPlaceholder(width: 96, height: 11, radius: MioRadii.sm),
        const SizedBox(height: MioSpacing.sm),
        const MioPlaceholder(width: 180, height: 22, radius: MioRadii.sm),
        const SizedBox(height: MioSpacing.md),
        const MioPlaceholderLines(lines: 5, lineHeight: 16),
      ],
    );
  }
}
