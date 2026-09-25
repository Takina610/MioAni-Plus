import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_detail_providers.dart';
import 'package:mio_ani/src/features/anime_detail/presentation/anime_detail_style.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/translation/domain/translation_candidate.dart';
import 'package:mio_ani/src/features/translation/presentation/translate_action.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// What the page has to say about a work, one section at a time.
enum _DetailSection {
  overview('概览'),
  relations('关联作品'),
  characters('角色声优'),
  staff('制作人员');

  const _DetailSection(this.label);

  final String label;
}

/// The sections of the page under the head, with the tab bar that switches
/// between them.
///
/// Only the section on screen is built, and each of the three that read from
/// the source starts reading when it is first opened — the head of the page is
/// about a work, and a reader who came for its summary should not wait on its
/// cast list. What is being read is drawn as the cards it will be, the way
/// every other wait in this app is drawn.
class AnimeDetailSections extends StatefulWidget {
  const AnimeDetailSections({
    required this.anime,
    required this.complete,
    super.key,
  });

  final AnimeSummary anime;

  /// Whether [anime] is the whole detail: a page that is still completing shows
  /// the summary as the lines it will be rather than claiming the source has
  /// none.
  final bool complete;

  @override
  State<AnimeDetailSections> createState() => _AnimeDetailSectionsState();
}

class _AnimeDetailSectionsState extends State<AnimeDetailSections> {
  _DetailSection _section = _DetailSection.overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DetailPillTabs(
          labels: <String>[
            for (final section in _DetailSection.values) section.label,
          ],
          index: _section.index,
          onChanged: (index) =>
              setState(() => _section = _DetailSection.values[index]),
        ),
        const SizedBox(height: MioSpacing.lg),
        DetailSoftSwitch(
          panelKey: ValueKey<_DetailSection>(_section),
          child: _panel(),
        ),
      ],
    );
  }

  Widget _panel() {
    final anime = widget.anime;
    return switch (_section) {
      _DetailSection.overview => _OverviewPanel(
        anime: anime,
        complete: widget.complete,
      ),
      _DetailSection.relations => _RelationsPanel(animeId: anime.id),
      _DetailSection.characters => _CharactersPanel(animeId: anime.id),
      _DetailSection.staff => _StaffPanel(animeId: anime.id),
    };
  }
}

/// A section's heading: what it is called in the source's own filing system,
/// what it is called here, and how much of it there is.
class _BlockHead extends StatelessWidget {
  const _BlockHead({
    required this.kicker,
    required this.title,
    this.count,
    this.action,
  });

  final String kicker;
  final String title;
  final String? count;

  /// An action belonging to the section, offered on the heading's own line: a
  /// heading that says what a block is, and the one thing a reader can do to
  /// it, read together.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MioSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DetailMicroLabel(kicker),
                const SizedBox(height: MioSpacing.xs),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (count != null) ...<Widget>[
                  const SizedBox(height: MioSpacing.xxs),
                  DetailMicroLabel(
                    count!,
                    color: MioColors.textSecondary,
                    size: 10,
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.anime, required this.complete});

  final AnimeSummary anime;
  final bool complete;

  /// Whether this work's synopsis is in a language its reader may not read.
  ///
  /// The characters decide, with the source's filing behind them: a work
  /// Bangumi files under China is a Chinese work, and its synopsis is Chinese
  /// however it is written.
  bool _synopsisReadsForeign(String synopsis) {
    return workTextReadsForeign(synopsis, origin: anime.origin);
  }

  @override
  Widget build(BuildContext context) {
    final synopsis = anime.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _BlockHead(
          kicker: 'OVERVIEW',
          title: '剧情与资料',
          // The offer sits on the heading and its answer lands under the
          // synopsis: the heads of the page's sections read the same way, and
          // a reader who has scrolled to the bottom of a long synopsis does not
          // have to scroll back up to put it away.
          action: synopsis == null
              ? null
              : MioTranslateButton(
                  source: synopsis,
                  variant: TranslationVariant.summary,
                  offered: _synopsisReadsForeign(synopsis),
                ),
        ),
        if (synopsis != null && synopsis.isNotEmpty)
          SelectableText(synopsis, style: _summaryStyle)
        else if (complete)
          const Text('来源暂未提供剧情简介。', style: _summaryStyle)
        else
          const MioPlaceholderLines(lines: 5, lineHeight: 16),
        if (synopsis != null && synopsis.isNotEmpty)
          MioTranslationOutput(
            source: synopsis,
            variant: TranslationVariant.summary,
            offered: _synopsisReadsForeign(synopsis),
          ),
        const SizedBox(height: MioSpacing.lg),
        _MiniMeta(anime: anime),
      ],
    );
  }

  static const TextStyle _summaryStyle = TextStyle(
    color: MioColors.textPrimary,
    fontSize: 15,
    height: 1.8,
  );
}

/// The handful of numbers about a work, on one line, for a reader who wants
/// them without opening the record.
class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.anime});

  final AnimeSummary anime;

  @override
  Widget build(BuildContext context) {
    final AnimeDetail? detail = switch (anime) {
      final AnimeDetail value => value,
      _ => null,
    };
    final items = <(IconData, String)>[
      if (anime.airDate case final date?)
        (Icons.calendar_today_outlined, '${date.year}'),
      if (anime.episodes case final episodes?)
        (Icons.movie_outlined, '$episodes 话'),
      if (detail?.durationMinutes case final minutes?)
        (Icons.schedule_outlined, '$minutes 分钟'),
      if (anime.score case final score?)
        (Icons.star_rounded, score.toStringAsFixed(1)),
      if (detail?.rank case final rank?) (Icons.tag, '#$rank'),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: MioSpacing.md,
      runSpacing: MioSpacing.xs,
      children: <Widget>[
        for (final (icon, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: MioColors.accent),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: MioColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _RelationsPanel extends ConsumerWidget {
  const _RelationsPanel({required this.animeId});

  final AnimeSourceId animeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relations = ref.watch(animeRelationsProvider(animeId));
    return _SectionBody<AnimeRelation>(
      value: relations,
      onRetry: () => refreshAnimeRelations(ref, animeId),
      kicker: 'RELATIONS',
      title: '关联作品',
      emptyMessage: '暂无关联作品。',
      metrics: (width) => _CardMetrics.relations(context, width),
      cardBuilder: (item, index) => DetailEnter(
        index: index,
        child: _RelationCard(relation: item),
      ),
    );
  }
}

class _CharactersPanel extends ConsumerWidget {
  const _CharactersPanel({required this.animeId});

  final AnimeSourceId animeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characters = ref.watch(animeCharactersProvider(animeId));
    return _SectionBody<AnimeCharacterCredit>(
      value: characters,
      onRetry: () => refreshAnimeCharacters(ref, animeId),
      kicker: 'CHARACTERS',
      title: '角色与声优',
      emptyMessage: '暂无角色资料。',
      countLabel: (items) => '共 ${items.length} 位',
      metrics: (width) => _CardMetrics.characters(
        context,
        width,
        // One card with an actor is enough to hold the actor's row open in
        // every card of the section, so a grid of them keeps one height.
        withActor:
            characters.value?.any((item) => item.voiceActorName != null) ??
            false,
      ),
      cardBuilder: (item, index) => DetailEnter(
        index: index,
        child: _CharacterCard(credit: item),
      ),
    );
  }
}

class _StaffPanel extends ConsumerWidget {
  const _StaffPanel({required this.animeId});

  final AnimeSourceId animeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(animeStaffProvider(animeId));
    return _SectionBody<AnimeStaffCredit>(
      value: staff,
      onRetry: () => refreshAnimeStaff(ref, animeId),
      kicker: 'STAFF',
      title: '制作人员',
      emptyMessage: '暂无制作人员资料。',
      countLabel: (items) => '共 ${items.length} 位',
      metrics: (width) => _CardMetrics.people(context, width),
      cardBuilder: (item, index) => DetailEnter(
        index: index,
        child: _StaffCard(credit: item),
      ),
    );
  }
}

/// One section's body in all four states it can be in: the cards it has, the
/// cards it is waiting for, a line saying there are none, or the failure and
/// the way to ask again.
///
/// The heading is drawn in every one of them. A section far down a page that
/// went quiet without saying what it was would leave a reader guessing which
/// part of the work is missing.
class _SectionBody<T> extends StatelessWidget {
  const _SectionBody({
    required this.value,
    required this.onRetry,
    required this.kicker,
    required this.title,
    required this.emptyMessage,
    required this.metrics,
    required this.cardBuilder,
    this.countLabel,
  });

  final AsyncValue<List<T>> value;
  final VoidCallback onRetry;
  final String kicker;
  final String title;
  final String emptyMessage;
  final _CardMetrics Function(double width) metrics;
  final Widget Function(T item, int index) cardBuilder;
  final String Function(List<T> items)? countLabel;

  /// Rows of cards a section that is still reading stands for: enough to fill
  /// a phone, and the reason a section does not jump when its answer lands.
  static const int _placeholderRows = 2;

  @override
  Widget build(BuildContext context) {
    final items = value.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardMetrics = metrics(constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _BlockHead(
              kicker: kicker,
              title: title,
              count: switch (items) {
                final List<T> items when items.isNotEmpty => countLabel?.call(
                  items,
                ),
                _ => null,
              },
            ),
            if (value.hasError && items == null)
              _SectionFailure(onRetry: onRetry)
            else if (items == null)
              _CardGrid(
                metrics: cardMetrics,
                count: cardMetrics.columns * _placeholderRows,
                builder: (context, index) => const _CardPlaceholder(),
              )
            else if (items.isEmpty)
              Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)
            else
              _CardGrid(
                metrics: cardMetrics,
                count: items.length,
                builder: (context, index) => cardBuilder(items[index], index),
              ),
          ],
        );
      },
    );
  }
}

class _SectionFailure extends StatelessWidget {
  const _SectionFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: Text('该分区加载失败，其余资料仍可使用。')),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}

/// Where a grid of cards sits on the window it is drawn in.
///
/// The reference lays its cards out the way a browser's `auto-fill` does: as
/// many columns as fit at the card's own minimum width, each of them sharing
/// what is left. Flutter's own `maxCrossAxisExtent` counts columns the other
/// way round — it rounds up — so the count is divided out here instead.
///
/// The height is the bottom half of the same idea. A row in a browser grid
/// stretches every card to the tallest one in it, and a card's height is its
/// text: which means a section's cards are as tall as its tallest text at the
/// text size the reader has set. Nothing here measures the text — every style
/// on these cards carries an explicit line height, so a line of it is its font
/// size times that height, and the card is the sum of its lines.
final class _CardMetrics {
  const _CardMetrics({
    required this.tileWidth,
    required this.cardHeight,
    required this.columns,
  });

  final double tileWidth;
  final double cardHeight;
  final int columns;

  /// Gap between two cards, both ways.
  static const double _gap = MioSpacing.sm;

  /// Padding inside a card, the hairline around it, and the width of a poster
  /// or a head in it. The hairline is not decoration that fits outside the
  /// card: it takes a pixel of the card's own inside on every side, so a row of
  /// text inside one is two pixels narrower than the card is.
  static const double _padding = 10;
  static const double _border = 1;
  static const double _relationPoster = 56;
  static const double _relationPosterHeight = 78;
  static const double _head = 72;
  static const double _actorHead = 32;

  factory _CardMetrics.relations(BuildContext context, double width) {
    return _of(
      width: width,
      minimumTile: 220,
      content: (tileWidth) => _max(
        _relationPosterHeight,
        _textHeight(context, style: _cardMicroStyle, lines: 1, maxWidth: 0) +
            4 +
            _textHeight(context, style: _cardTitleStyle, lines: 2, maxWidth: 0),
      ),
    );
  }

  factory _CardMetrics.characters(
    BuildContext context,
    double width, {
    required bool withActor,
  }) {
    return _of(
      width: width,
      minimumTile: 240,
      content: (tileWidth) => _max(
        _head,
        _textHeight(context, style: _cardTitleStyle, lines: 1, maxWidth: 0) +
            4 +
            _textHeight(context, style: _cardMetaStyle, lines: 1, maxWidth: 0) +
            (withActor ? 8 + _actorHead : 0),
      ),
    );
  }

  factory _CardMetrics.people(BuildContext context, double width) {
    return _of(
      width: width,
      minimumTile: 240,
      content: (tileWidth) => _max(
        _head,
        _textHeight(context, style: _cardTitleStyle, lines: 1, maxWidth: 0) +
            4 +
            _textHeight(context, style: _cardMetaStyle, lines: 1, maxWidth: 0),
      ),
    );
  }

  /// How tall [lines] of [style] paint, measured by the same engine that will
  /// paint them rather than multiplied out from the font size: a line of text
  /// is its font size times its height only until the engine rounds it, and the
  /// rounding is what a card sized by arithmetic runs out of room on.
  ///
  /// [maxWidth] only decides where the text wraps; these lines are one or two
  /// of a single word each, so they do not.
  static double _textHeight(
    BuildContext context, {
    required TextStyle style,
    required int lines,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: '最长的动画标题' * 4, style: style),
      maxLines: lines,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.height;
  }

  static _CardMetrics _of({
    required double width,
    required double minimumTile,
    required double Function(double tileWidth) content,
  }) {
    // A grid can be asked to lay out before the window it is in has a width —
    // the first frame of a cold start — and a tile cannot be divided out of
    // nothing.
    final available = width.isFinite && width > 0 ? width : minimumTile;
    final columns = _maxInt(
      1,
      ((available + _gap) / (minimumTile + _gap)).floor(),
    );
    final tileWidth = (available - (columns - 1) * _gap) / columns;
    return _CardMetrics(
      tileWidth: tileWidth,
      cardHeight: _padding * 2 + _border * 2 + content(tileWidth),
      columns: columns,
    );
  }

  static double _max(double a, double b) => a > b ? a : b;

  static int _maxInt(int a, int b) => a > b ? a : b;
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.metrics,
    required this.count,
    required this.builder,
  });

  final _CardMetrics metrics;
  final int count;
  final Widget Function(BuildContext context, int index) builder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: metrics.columns,
        mainAxisSpacing: _CardMetrics._gap,
        crossAxisSpacing: _CardMetrics._gap,
        mainAxisExtent: metrics.cardHeight,
      ),
      itemCount: count,
      itemBuilder: builder,
    );
  }
}

/// The box a card's picture goes in, filled with the surface colour when the
/// source has no picture for it.
///
/// A person published without a portrait is not a broken image: [MioImage]
/// answers a missing URL with the icon it uses for a failure, which on a card
/// like this reads as the page having failed rather than as the source having
/// nothing. The reference draws these as a bare block, and so does this.
class _Picture extends StatelessWidget {
  const _Picture({
    required this.imageUrl,
    required this.semanticLabel,
    required this.width,
    required this.height,
  });

  final Uri? imageUrl;
  final String semanticLabel;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: MioColors.surfaceHigh,
          borderRadius: BorderRadius.circular(MioRadii.sm),
        ),
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: MioImage(
        imageUrl: imageUrl,
        semanticLabel: semanticLabel,
        alignment: Alignment.topCenter,
        borderRadius: MioRadii.sm,
      ),
    );
  }
}

/// A card whose content has not arrived: the same rectangle the real card will
/// take, so the section does not move when it lands.
class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const MioPlaceholder.expand();
  }
}

/// A work related to this one: its poster, how it relates, and its name.
class _RelationCard extends StatelessWidget {
  const _RelationCard({required this.relation});

  final AnimeRelation relation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '查看 ${relation.title} 详情',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => unawaited(
            AnimeDetailRouteData(
              id: relation.animeId.value,
            ).push<void>(context),
          ),
          borderRadius: BorderRadius.circular(MioRadii.md),
          child: Container(
            padding: const EdgeInsets.all(_CardMetrics._padding),
            decoration: detailBlock(),
            child: Row(
              children: <Widget>[
                _Picture(
                  imageUrl: relation.imageUrl,
                  semanticLabel: relation.title,
                  width: _CardMetrics._relationPoster,
                  height: _CardMetrics._relationPosterHeight,
                ),
                const SizedBox(width: MioSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (relation.relation case final label?) ...<Widget>[
                        DetailMicroLabel(label.toUpperCase(), size: 10),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        relation.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _cardTitleStyle,
                      ),
                    ],
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

/// A character and the actor behind them.
///
/// The portrait is a square of the character's own picture, kept at its top:
/// a character is published as a portrait, a card wants a head, and a head
/// lives at the top of a picture rather than in the middle of one. The actor's
/// row is its own target — it opens the actor, not the character.
class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.credit});

  final AnimeCharacterCredit credit;

  @override
  Widget build(BuildContext context) {
    final actorName = credit.voiceActorName;
    return Container(
      padding: const EdgeInsets.all(_CardMetrics._padding),
      decoration: detailBlock(),
      child: Row(
        children: <Widget>[
          _Picture(
            imageUrl: credit.imageUrl,
            semanticLabel: credit.name,
            width: _CardMetrics._head,
            height: _CardMetrics._head,
          ),
          const SizedBox(width: MioSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  credit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _cardTitleStyle,
                ),
                const SizedBox(height: 4),
                Text(
                  credit.role ?? '角色',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _cardMetaStyle,
                ),
                if (actorName != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _ActorRow(credit: credit, name: actorName),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActorRow extends StatelessWidget {
  const _ActorRow({required this.credit, required this.name});

  final AnimeCharacterCredit credit;
  final String name;

  @override
  Widget build(BuildContext context) {
    final actorId = credit.voiceActorId;
    final row = Row(
      children: <Widget>[
        _Picture(
          imageUrl: credit.voiceActorImageUrl,
          semanticLabel: '$name 头像',
          width: _CardMetrics._actorHead,
          height: _CardMetrics._actorHead,
        ),
        const SizedBox(width: MioSpacing.xs),
        Expanded(
          child: Text(
            'CV · $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _cardMetaStyle,
          ),
        ),
      ],
    );
    if (actorId == null) return row;
    return Semantics(
      button: true,
      label: '查看声优 $name 详情',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => unawaited(
            PersonDetailRouteData(id: actorId.value).push<void>(context),
          ),
          borderRadius: BorderRadius.circular(MioRadii.sm),
          child: row,
        ),
      ),
    );
  }
}

/// One of the people who made the work, and what they did on it.
class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.credit});

  final AnimeStaffCredit credit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '查看 ${credit.name} 详情',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => unawaited(
            PersonDetailRouteData(
              id: credit.personId.value,
            ).push<void>(context),
          ),
          borderRadius: BorderRadius.circular(MioRadii.md),
          child: Container(
            padding: const EdgeInsets.all(_CardMetrics._padding),
            decoration: detailBlock(),
            child: Row(
              children: <Widget>[
                _Picture(
                  imageUrl: credit.imageUrl,
                  semanticLabel: credit.name,
                  width: _CardMetrics._head,
                  height: _CardMetrics._head,
                ),
                const SizedBox(width: MioSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        credit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _cardTitleStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        credit.role ?? '制作',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _cardMetaStyle,
                      ),
                    ],
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

const TextStyle _cardTitleStyle = TextStyle(
  color: MioColors.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w700,
  height: 1.35,
);

/// The relation label over a card's title, matching [DetailMicroLabel] at its
/// smallest: the measurement has to be of the style that will paint.
const TextStyle _cardMicroStyle = TextStyle(
  color: MioColors.accent,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
  height: 1.2,
);

const TextStyle _cardMetaStyle = TextStyle(
  color: MioColors.textSecondary,
  fontSize: 11,
  height: 1.4,
);
