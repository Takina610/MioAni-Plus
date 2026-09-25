import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_style.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/translation/domain/translation_candidate.dart';
import 'package:mio_ani/src/features/translation/presentation/translate_action.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// Where every part of the head of the page sits on a window of a given width.
///
/// The numbers are the reference's own, read off its breakpoints: the poster is
/// 180 across once there is room for a column of text beside it and shrinks to
/// 132 when there is less, under 600 it is centred alone and sized from the
/// window (`48%`, capped), and the summary under the title gets two more lines
/// when the text owns the full width.
final class DetailHeaderMetrics {
  const DetailHeaderMetrics({
    required this.stacked,
    required this.posterWidth,
    required this.titleSize,
    required this.leadLines,
    required this.bannerHeight,
    required this.sidePadding,
    required this.topPadding,
  });

  /// Whether the poster sits above the text instead of beside it.
  final bool stacked;
  final double posterWidth;
  final double titleSize;
  final int leadLines;

  /// Height of the art band behind the head.
  final double bannerHeight;

  /// Space between the page edge and the head's content.
  final double sidePadding;

  /// Space above the head's content: clear of the status bar and of the glass
  /// back button over it, so nothing the head draws lands under either.
  final double topPadding;

  factory DetailHeaderMetrics.of(BuildContext context, double width) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final sidePadding = (width * 0.04)
        .clamp(MioSpacing.md, MioSpacing.xxl)
        .toDouble();
    final topPadding = math.max(64.0, safeTop + MioSpacing.xxl);
    final windowClass = MioBreakpoints.windowClassFor(width);
    final stacked = windowClass == MioWindowClass.compact;
    return DetailHeaderMetrics(
      stacked: stacked,
      posterWidth: switch (windowClass) {
        MioWindowClass.compact => math.min(180, width * 0.48),
        MioWindowClass.medium => 132,
        MioWindowClass.expanded => 180,
      },
      // The reference clamps the title to 4.4% of the window between 28 and 42.
      titleSize: stacked ? 28 : (width * 0.044).clamp(28, 42).toDouble(),
      leadLines: stacked ? 6 : 4,
      bannerHeight: math.min(320, MediaQuery.sizeOf(context).height * 0.42),
      sidePadding: sidePadding,
      topPadding: topPadding,
    );
  }
}

/// The head of the page: the work's art behind, its poster and its names in
/// front, and the opening of its summary under them.
///
/// It draws from an [AnimeSummary] rather than from the full detail, because
/// that is what a list already knew when it was tapped through: the art, the
/// names and the opening lines are on screen before the subject request has
/// answered, and [complete] only decides whether the pieces that answer carries
/// are drawn as themselves or as the blocks they will fill.
class AnimeDetailHeader extends StatelessWidget {
  const AnimeDetailHeader({
    required this.anime,
    required this.complete,
    super.key,
  });

  final AnimeSummary anime;

  /// Whether [anime] is the whole detail, as opposed to what a list knew.
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = DetailHeaderMetrics.of(context, constraints.maxWidth);
        return Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: metrics.bannerHeight,
              child: _DetailBanner(anime: anime),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.sidePadding,
                metrics.topPadding,
                metrics.sidePadding,
                MioSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[_head(context, metrics)],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _head(BuildContext context, DetailHeaderMetrics metrics) {
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    final text = Column(
      crossAxisAlignment: metrics.stacked
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        DetailMicroLabel(
          '${anime.sourceLabel.toUpperCase()} · ${anime.id.rawId}',
        ),
        const SizedBox(height: MioSpacing.xs),
        Text(
          title,
          textAlign: metrics.stacked ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: MioColors.textPrimary,
            fontSize: metrics.titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.12,
          ),
        ),
        if (anime.sourceTitle.isNotEmpty &&
            anime.sourceTitle != anime.title) ...[
          const SizedBox(height: MioSpacing.xs),
          Text(
            anime.sourceTitle,
            textAlign: metrics.stacked ? TextAlign.center : TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        // A work whose Chinese name the source never filled in is the whole
        // reason this page has a Japanese title, so the offer is made on the
        // title itself and its answer lands directly under it. A title is the
        // one text on the page whose language the source has already settled —
        // see [workTitleReadsForeign] — so it does not have to be guessed at.
        MioTranslateAction(
          source: title,
          variant: TranslationVariant.title,
          offered: workTitleReadsForeign(
            title: anime.title,
            sourceTitle: anime.sourceTitle,
            origin: anime.origin,
          ),
          alignment: metrics.stacked
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
        ),
        const SizedBox(height: MioSpacing.md),
        _lead(context, metrics),
      ],
    );

    final poster = _poster(context, metrics);
    if (!metrics.stacked) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          poster,
          const SizedBox(width: MioSpacing.xl),
          Expanded(child: text),
        ],
      );
    }
    // On a phone the reference centres the poster over the text, which is also
    // where a reader's thumb is not.
    return Column(
      children: <Widget>[
        poster,
        const SizedBox(height: MioSpacing.xl),
        text,
      ],
    );
  }

  Widget _poster(BuildContext context, DetailHeaderMetrics metrics) {
    final width = metrics.posterWidth;
    final height = width * 1.5;
    final title = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MioRadii.md),
        border: Border.all(color: MioColors.outline.withValues(alpha: 0.28)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MioRadii.md),
        child: SizedBox(
          width: width,
          height: height,
          child: MioImage(
            imageUrl: anime.imageUrl,
            semanticLabel: '$title 海报',
            borderRadius: 0,
          ),
        ),
      ),
    );
  }

  /// The opening of the summary, three or four lines of it.
  ///
  /// It stops where the head has room rather than growing into the page: the
  /// full text is what the overview section is for, and a head that keeps going
  /// pushes the facts, the tabs and everything else below the fold.
  Widget _lead(BuildContext context, DetailHeaderMetrics metrics) {
    final synopsis = anime.summary;
    if (synopsis == null || synopsis.isEmpty) {
      if (!complete) return const MioPlaceholderLines(lines: 4, lineHeight: 16);
      return Text(
        '来源暂未提供剧情简介。',
        textAlign: metrics.stacked ? TextAlign.center : TextAlign.start,
        style: _leadStyle(context),
      );
    }
    return Text(
      synopsis,
      maxLines: metrics.leadLines,
      overflow: TextOverflow.ellipsis,
      textAlign: metrics.stacked ? TextAlign.center : TextAlign.start,
      style: _leadStyle(context),
    );
  }

  TextStyle _leadStyle(BuildContext context) {
    return TextStyle(
      color: MioColors.textPrimary.withValues(alpha: 0.82),
      fontSize: 14,
      height: 1.75,
    );
  }
}

/// The art behind the head: the cover, half-strength, dissolved into the page
/// before it reaches the content.
///
/// The source publishes one picture per work — a portrait cover — so the band
/// takes its top edge, which is where a cover puts its subject, and the two
/// gradients do the rest: the mask fades the art out, and the shade walks the
/// page's own colour back in underneath the title.
class _DetailBanner extends StatelessWidget {
  const _DetailBanner({required this.anime});

  final AnimeSummary anime;

  /// Stops both gradients read from the reference: solid art to 56%, then the
  /// fade, then nothing.
  static const List<double> _stops = <double>[0, 0.56, 0.78, 1];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black,
              Colors.black,
              Color(0x85000000),
              Color(0x00000000),
            ],
            stops: _stops,
          ).createShader(bounds),
          child: Opacity(
            opacity: 0.5,
            child: MioImageBackdrop(
              imageUrl: anime.imageUrl,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                MioColors.background.withValues(alpha: 0.2),
                MioColors.background.withValues(alpha: 0.88),
                MioColors.background.withValues(alpha: 0.52),
                MioColors.background.withValues(alpha: 0),
              ],
              stops: _stops,
            ),
          ),
        ),
      ],
    );
  }
}
