import 'package:flutter/material.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_style.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/translation/domain/translation_candidate.dart';
import 'package:mio_ani/src/features/translation/presentation/translate_action.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// One line of a work's record: what the fact is, and what it says.
final class _DetailFact {
  const _DetailFact(this.label, this.value);

  final String label;
  final String value;
}

/// The facts a work can state about itself, in the order they are worth
/// reading.
///
/// Only what the work actually carries is listed: a fact the source did not
/// publish is left out rather than drawn as a dash, so the board is short for
/// an entry nobody has filled in and long for one that has. There is no year
/// of its own — the source's only date is the one the work started airing, and
/// a board that says `2008` and `2008-04-06` one line apart is saying one thing
/// twice — and no score either, which the card above the facts already holds.
List<_DetailFact> _factsOf(AnimeSummary anime) {
  final facts = <_DetailFact>[
    if (anime.episodes case final episodes?) _DetailFact('话数', '$episodes 话'),
    if (anime.airDate case final date?) _DetailFact('开播', _day(date)),
  ];
  if (anime is AnimeDetail) {
    if (anime.format case final format?) {
      facts.insert(0, _DetailFact('格式', format));
    }
    if (anime.durationMinutes case final minutes?) {
      facts.add(_DetailFact('单集时长', '$minutes 分钟'));
    }
    if (anime.studio case final studio?) {
      facts.add(_DetailFact('制作', studio));
    }
    if (anime.sourceMaterial case final material?) {
      facts.add(_DetailFact('原作', material));
    }
  }
  facts.add(_DetailFact('来源', anime.sourceLabel));
  return facts;
}

String _day(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// A work's record beside the page: the score it is held at, what it is, and
/// what it is filed under.
///
/// A window wide enough to hold two columns keeps the board open down its side,
/// where it is read at a glance while the sections change next to it. A phone
/// gets one line of it instead — a board a reader has to scroll past before
/// reaching what they came for is a board they scroll past — which opens to the
/// same facts when they ask for them, and says in caps on that line the three
/// numbers they most often want.
class AnimeDetailMetaBoard extends StatefulWidget {
  const AnimeDetailMetaBoard({
    required this.anime,
    required this.collapsible,
    super.key,
  });

  final AnimeSummary anime;

  /// Whether the page has put this board in the column beside the sections, or
  /// in a single column where it is one line that opens.
  ///
  /// The page already knows which of the two it laid out; asking the window
  /// again here would be the same question twice, and the two answers would
  /// part company the first time a page was drawn somewhere narrower than the
  /// window it sits in.
  final bool collapsible;

  @override
  State<AnimeDetailMetaBoard> createState() => _AnimeDetailMetaBoardState();
}

class _AnimeDetailMetaBoardState extends State<AnimeDetailMetaBoard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final blocks = _blocks(context);
    if (blocks.isEmpty) return const SizedBox.shrink();
    if (!widget.collapsible) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _stacked(blocks),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _toggle(context),
        // Closed is closed: the board is not built until it is asked for, so a
        // phone neither lays out a column of facts it is not showing nor lets a
        // reader's thumb land on one of them.
        AnimatedSwitcher(
          duration: MioMotion.resolve(context, MioDurations.medium),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            // The board grows out of the line that opened it: for a vertical
            // transition, `Alignment(-1, y)` is the top edge.
            alignment: Alignment.topLeft,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: _expanded
              ? Padding(
                  key: const ValueKey<String>('record'),
                  padding: const EdgeInsets.only(top: MioSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _stacked(blocks),
                  ),
                )
              : const SizedBox(
                  key: ValueKey<String>('record-closed'),
                  width: double.infinity,
                ),
        ),
      ],
    );
  }

  /// The blocks one under the other, spaced, wherever they are stacked.
  static List<Widget> _stacked(List<Widget> blocks) {
    return <Widget>[
      for (final block in blocks) ...<Widget>[
        if (block != blocks.first) const SizedBox(height: MioSpacing.sm),
        block,
      ],
    ];
  }

  /// The line a phone shows instead of the board: what it is, the numbers worth
  /// knowing without opening anything, and the way in.
  Widget _toggle(BuildContext context) {
    final anime = widget.anime;
    final rank = anime is AnimeDetail ? anime.rank : null;
    final summary = <String>[
      if (anime.score case final score?) score.toStringAsFixed(1),
      if (rank != null) '#$rank',
      if (anime.airDate case final date?) '${date.year}',
    ];
    return Semantics(
      button: true,
      expanded: _expanded,
      label: '作品资料',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(MioRadii.md),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: MioSpacing.md),
            decoration: detailBlock(),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '作品资料',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MioColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // The numbers give way before the label does — a line that says
                // what the record is still names the record — and a reader who
                // has asked for the largest text their phone offers gets what
                // fits of them rather than a line pushed out of its own box.
                for (final value in summary) ...<Widget>[
                  const SizedBox(width: MioSpacing.sm),
                  Flexible(
                    child: DetailMicroLabel(
                      value,
                      color: MioColors.textSecondary,
                      size: 11,
                    ),
                  ),
                ],
                const SizedBox(width: MioSpacing.xs),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: MioMotion.resolve(context, MioDurations.medium),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.expand_more,
                    size: 18,
                    color: MioColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _blocks(BuildContext context) {
    final anime = widget.anime;
    final detail = anime is AnimeDetail ? anime : null;
    final rank = detail?.rank;
    return <Widget>[
      if (anime.score case final score?)
        _RankCard(
          score: score,
          // The rank rides on the score rather than standing as a fact of its
          // own: a rank is a reading of the same rating, and the two belong
          // together the way the reference draws them.
          caption: rank == null ? '${anime.sourceLabel} 评分' : '#$rank 排名',
        ),
      for (final fact in _factsOf(anime))
        _FactBlock(key: ValueKey<String>(fact.label), fact: fact),
      if (detail != null && detail.tags.isNotEmpty)
        _TagsBlock(tags: detail.tags, origin: anime.origin),
    ];
  }
}

/// The score, held the way the source holds it, with the rank it earned.
class _RankCard extends StatelessWidget {
  const _RankCard({required this.score, required this.caption});

  final double score;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MioSpacing.md,
        vertical: MioSpacing.sm,
      ),
      decoration: detailBlock(accent: true),
      child: Row(
        children: <Widget>[
          const Icon(Icons.star_rounded, color: MioColors.accent, size: 20),
          const SizedBox(width: MioSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  score.toStringAsFixed(1),
                  style: const TextStyle(
                    color: MioColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                DetailMicroLabel(
                  caption,
                  color: MioColors.textSecondary,
                  size: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactBlock extends StatelessWidget {
  const _FactBlock({required this.fact, super.key});

  final _DetailFact fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: MioSpacing.md,
        vertical: MioSpacing.sm,
      ),
      decoration: detailBlock(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DetailMicroLabel(
            fact.label,
            color: MioColors.textSecondary,
            size: 10,
          ),
          const SizedBox(height: 5),
          Text(
            fact.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MioColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the work is filed under: the source's own tags, in the app's colour.
class _TagsBlock extends StatelessWidget {
  const _TagsBlock({required this.tags, this.origin});

  final List<String> tags;
  final WorkOrigin? origin;

  @override
  Widget build(BuildContext context) {
    // The tags of a work are usually Chinese already — the source is a Chinese
    // one, and a work's tags are the words its readers filed it under. An entry
    // tagged in Japanese or English is the exception, and the offer is only
    // made for one: the rule decides, here as everywhere.
    final joined = tags.join(' · ');
    final offered = workTextReadsForeign(joined, origin: origin);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // A row of two would be wider than the record rail at a large text
        // size, so the offer drops to the next line instead of pushing the
        // label out of the block it names.
        Wrap(
          spacing: MioSpacing.xs,
          runSpacing: MioSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            const DetailMicroLabel(
              '标签',
              color: MioColors.textSecondary,
              size: 10,
            ),
            MioTranslateButton(
              source: joined,
              variant: TranslationVariant.tags,
              offered: offered,
            ),
          ],
        ),
        const SizedBox(height: MioSpacing.xs),
        Wrap(
          spacing: MioSpacing.xs,
          runSpacing: MioSpacing.xs,
          children: <Widget>[
            for (final tag in tags)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MioSpacing.xs,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: MioColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: MioColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        MioTranslationOutput(
          source: joined,
          variant: TranslationVariant.tags,
          offered: offered,
        ),
      ],
    );
  }
}
