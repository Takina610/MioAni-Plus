import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/routing/anime_detail_navigation.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_cover_flight.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/application/discover_providers.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query_codec.dart';
import 'package:mio_ani/src/features/discover/domain/discover_state.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({required this.initialUri, super.key});

  final Uri initialUri;

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  static const _codec = DiscoverQueryCodec();
  late DiscoverQuery _query;
  late final TextEditingController _keywordController;
  bool _filterOpen = false;
  Timer? _routeDebounce;

  @override
  void initState() {
    super.initState();
    _query = _codec.parse(widget.initialUri);
    _keywordController = TextEditingController(text: _query.keyword);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRouteQuery());
  }

  @override
  void didUpdateWidget(covariant DiscoverPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _codec.parse(widget.initialUri);
    if (next != _query) {
      _query = next;
      _keywordController.value = TextEditingValue(
        text: next.keyword,
        selection: TextSelection.collapsed(offset: next.keyword.length),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncRouteQuery());
    }
  }

  /// Pushes the route query into the controller. The first call also starts the
  /// initial load; later calls are no-ops unless the route actually moved.
  void _syncRouteQuery() {
    if (!mounted) return;
    ref
        .read(discoverControllerProvider.notifier)
        .setQuery(_query, immediate: true);
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final windowClass = MioBreakpoints.windowClassFor(width);
    final filters = _FilterSummary(query: _query, onClear: _clearFilters);
    return Scaffold(
      // The brand backdrop belongs to the shell, behind every branch.
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(discoverControllerProvider.notifier).refresh();
            await Future<void>.delayed(const Duration(milliseconds: 80));
          },
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(child: _header(context, state, windowClass)),
              SliverToBoxAdapter(child: filters),
              if (windowClass != MioWindowClass.compact && _filterOpen)
                SliverToBoxAdapter(
                  child: _FilterPanel(
                    query: _query,
                    onChanged: _applyQuery,
                    catalog: state.filterCatalog,
                  ),
                ),
              if (state.status == DiscoverStatus.loading && state.items.isEmpty)
                // A search that has not answered yet stands up as the grid it
                // will be: cards of the same size in the same places, so the
                // results land in a page that is already there.
                _skeletonGrid(windowClass)
              else if (state.status == DiscoverStatus.firstPageError &&
                  state.items.isEmpty)
                SliverFillRemaining(
                  child: MioStateView.failure(
                    failure: state.failure ?? const UnknownFailure(),
                    onRetry: () =>
                        ref.read(discoverControllerProvider.notifier).retry(),
                  ),
                )
              else if (state.items.isEmpty)
                const SliverFillRemaining(
                  child: MioStateView.empty(
                    title: '没有找到作品',
                    message: '可以调整关键词或筛选条件后重试。',
                  ),
                )
              else ...<Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    MioSpacing.lg,
                    MioSpacing.md,
                    MioSpacing.lg,
                    MioSpacing.lg,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => index < state.items.length
                          ? _AnimeCard(anime: state.items[index])
                          : const _AnimeCardPlaceholder(),
                      // A page on its way is drawn as the cards it will bring,
                      // in the grid they will land in.
                      childCount:
                          state.items.length +
                          (state.status == DiscoverStatus.loadingMore
                              ? _pendingCards
                              : 0),
                    ),
                    gridDelegate: _gridDelegate(windowClass),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _LoadMore(
                    state: state,
                    onRetry: () => ref
                        .read(discoverControllerProvider.notifier)
                        .loadMore(),
                    onLoad: () => ref
                        .read(discoverControllerProvider.notifier)
                        .loadMore(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: windowClass == MioWindowClass.compact
          ? FloatingActionButton.extended(
              onPressed: () => _openFilters(state),
              icon: const Icon(Icons.tune),
              label: const Text('筛选'),
            )
          : null,
    );
  }

  Widget _header(
    BuildContext context,
    DiscoverState state,
    MioWindowClass windowClass,
  ) {
    final source = state.source?.label ?? '自动';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MioSpacing.lg,
        MioSpacing.lg,
        MioSpacing.lg,
        MioSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '发现',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Chip(label: Text(source)),
              if (windowClass != MioWindowClass.compact)
                IconButton(
                  tooltip: _filterOpen ? '收起筛选' : '展开筛选',
                  onPressed: () => setState(() => _filterOpen = !_filterOpen),
                  icon: Icon(
                    _filterOpen ? Icons.filter_alt_off : Icons.filter_alt,
                  ),
                ),
            ],
          ),
          const SizedBox(height: MioSpacing.sm),
          TextField(
            controller: _keywordController,
            decoration: InputDecoration(
              hintText: '搜索动画、漫画或制作团队',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _keywordController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清空关键词',
                      onPressed: () {
                        _keywordController.clear();
                        _applyQuery(_query.copyWith(keyword: ''), true);
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              _applyQuery(_query.copyWith(keyword: value));
              setState(() {});
            },
            onSubmitted: (value) =>
                _applyQuery(_query.copyWith(keyword: value), true),
          ),
          if (state.status == DiscoverStatus.contentStale ||
              state.status == DiscoverStatus.refreshing)
            Padding(
              padding: const EdgeInsets.only(top: MioSpacing.xs),
              child: Text(
                '当前显示缓存结果，正在更新…',
                style: TextStyle(color: MioColors.warning),
              ),
            ),
          if (state.status == DiscoverStatus.rateLimited)
            Padding(
              padding: const EdgeInsets.only(top: MioSpacing.xs),
              child: Text(
                '请求过于频繁，请稍后重试。',
                style: TextStyle(color: MioColors.warning),
              ),
            ),
        ],
      ),
    );
  }

  void _applyQuery(DiscoverQuery query, [bool immediate = false]) {
    final next = query.normalized();
    if (next == _query) return;
    setState(() => _query = next);
    final uri = _codec.apply(Uri(path: '/discover'), next);
    if (GoRouterState.of(context).uri != uri) context.go(uri.toString());
    ref
        .read(discoverControllerProvider.notifier)
        .setQuery(next, immediate: immediate);
  }

  void _clearFilters() {
    _applyQuery(DiscoverQuery(keyword: _query.keyword));
  }

  Future<void> _openFilters(DiscoverState state) async {
    final selected = await showModalBottomSheet<DiscoverQuery>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _FilterPanel(
          query: _query,
          catalog: state.filterCatalog,
          onChanged: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (selected != null && mounted) _applyQuery(selected, true);
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({required this.query, required this.onClear});
  final DiscoverQuery query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (query.year != null) {
      chips.add(Chip(label: Text('${query.year}年')));
    }
    if (query.season != null) {
      chips.add(Chip(label: Text(query.season!.label)));
    }
    if (query.airStatus != DiscoverAirStatus.all) {
      chips.add(Chip(label: Text(query.airStatus.label)));
    }
    if (query.format != DiscoverFormat.all) {
      chips.add(Chip(label: Text(query.format.label)));
    }
    if (query.scoreMin != null || query.scoreMax != null) {
      chips.add(
        Chip(
          label: Text('评分 ${query.scoreMin ?? 0} - ${query.scoreMax ?? 10}'),
        ),
      );
    }
    if (query.genres.isNotEmpty) {
      chips.add(Chip(label: Text('题材 ${query.genres.length}')));
    }
    if (query.sourcePreference != DiscoverSourcePreference.auto) {
      chips.add(Chip(label: Text(query.sourcePreference.queryValue)));
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MioSpacing.lg),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Wrap(
              spacing: MioSpacing.xs,
              runSpacing: MioSpacing.xs,
              children: chips,
            ),
          ),
          TextButton(onPressed: onClear, child: const Text('清除')),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    required this.query,
    required this.onChanged,
    this.catalog,
  });
  final DiscoverQuery query;
  final DiscoverFilterCatalog? catalog;
  final ValueChanged<DiscoverQuery> onChanged;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late DiscoverQuery value = widget.query;

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    return Card(
      margin: const EdgeInsets.fromLTRB(
        MioSpacing.lg,
        MioSpacing.sm,
        MioSpacing.lg,
        0,
      ),
      child: Padding(
        padding: const EdgeInsets.all(MioSpacing.md),
        child: Wrap(
          spacing: MioSpacing.md,
          runSpacing: MioSpacing.md,
          children: <Widget>[
            _select<DiscoverSourcePreference>(
              '来源',
              value.sourcePreference,
              DiscoverSourcePreference.values,
              (next) => value = value.copyWith(sourcePreference: next),
              (item) => item.queryValue,
            ),
            _select<DiscoverSort>(
              '排序',
              value.sort,
              DiscoverSort.values,
              (next) => value = value.copyWith(sort: next),
              (item) => item.label,
            ),
            _select<DiscoverFormat>(
              '格式',
              value.format,
              DiscoverFormat.values,
              (next) => value = value.copyWith(format: next),
              (item) => item.label,
            ),
            _select<DiscoverAirStatus>(
              '状态',
              value.airStatus,
              DiscoverAirStatus.values,
              (next) => value = value.copyWith(airStatus: next),
              (item) => item.label,
            ),
            SizedBox(
              width: 180,
              child: TextFormField(
                initialValue: value.year?.toString(),
                decoration: const InputDecoration(
                  labelText: '年份',
                  hintText: '例如 2026',
                ),
                keyboardType: TextInputType.number,
                onChanged: (text) {
                  final year = int.tryParse(text);
                  value = value.copyWith(year: year, clearYear: text.isEmpty);
                },
              ),
            ),
            if (catalog != null)
              SizedBox(
                width: 280,
                child: Text(
                  '题材：${catalog.genres.take(6).join('、')}${catalog.isFallback ? '（回退列表）' : ''}',
                ),
              ),
            FilledButton.tonal(
              onPressed: () => widget.onChanged(value),
              child: const Text('应用筛选'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _select<T>(
    String label,
    T selected,
    List<T> values,
    ValueChanged<T> update,
    String Function(T) text,
  ) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<T>(
        initialValue: selected,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (item) =>
                  DropdownMenuItem<T>(value: item, child: Text(text(item))),
            )
            .toList(),
        onChanged: (next) {
          if (next == null) return;
          setState(() => update(next));
        },
      ),
    );
  }
}

/// How many cards a search that has not answered stands up: enough to fill a
/// phone screen of the smallest tiles; a wide window simply shows the same
/// shape more times.
const int _skeletonCards = 6;

/// How many cards stand in for a page whose results are on their way, inside
/// the grid those results will land in.
const int _pendingCards = 3;

/// Geometry of the results grid, shared by the results and by the cards drawn
/// while they are still being read — so a skeleton tile is exactly as big as
/// the card that replaces it.
SliverGridDelegate _gridDelegate(MioWindowClass windowClass) {
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: windowClass == MioWindowClass.expanded ? 220 : 180,
    mainAxisExtent: 350,
    crossAxisSpacing: MioSpacing.md,
    mainAxisSpacing: MioSpacing.md,
  );
}

/// The results grid before the first page of results is known.
SliverPadding _skeletonGrid(MioWindowClass windowClass) {
  return SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      MioSpacing.lg,
      MioSpacing.md,
      MioSpacing.lg,
      MioSpacing.lg,
    ),
    sliver: SliverGrid(
      gridDelegate: _gridDelegate(windowClass),
      delegate: SliverChildBuilderDelegate(
        (context, index) => const _AnimeCardPlaceholder(),
        childCount: _skeletonCards,
      ),
    ),
  );
}

/// A result card before its anime is known: the same poster box, the same two
/// title lines and the same chip row, so the results land in a grid that is
/// already standing.
class _AnimeCardPlaceholder extends StatelessWidget {
  const _AnimeCardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Expanded(
            child: SizedBox(
              width: double.infinity,
              child: MioPlaceholder(radius: 0),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              MioSpacing.sm,
              MioSpacing.sm,
              MioSpacing.sm,
              MioSpacing.xs,
            ),
            child: MioPlaceholderLines(lines: 2, lineHeight: 16),
          ),
          // A Wrap, like the chips it stands for: in a narrow tile the real
          // chips take a second row, and the placeholder has to be able to.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: MioSpacing.sm),
            child: Wrap(
              spacing: MioSpacing.xs,
              runSpacing: MioSpacing.xxs,
              children: <Widget>[
                MioPlaceholder(width: 56, height: 32, radius: 16),
                MioPlaceholder(width: 84, height: 32, radius: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimeCard extends ConsumerWidget {
  const _AnimeCard({required this.anime});
  final AnimeSummary anime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The result's picture, and the one a tap sends to the detail page's
    // poster. The discover page is a list of its own, so its cards carry their
    // own place in the tag even for a work the home page is showing too.
    final cover = AnimeCoverFlight.tile(
      anime: anime,
      place: AnimeCoverPlace.discover,
    );
    return Semantics(
      button: true,
      label: anime.title,
      child: InkWell(
        onTap: () => openAnimeDetail(context, ref, anime, cover: cover),
        borderRadius: BorderRadius.circular(MioRadii.md),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // The poster absorbs the slack: score and source chips wrap onto
              // extra rows in narrow tiles and must not overflow the card.
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: AnimeCoverSource(
                    flight: cover,
                    semanticLabel: anime.title,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MioSpacing.sm,
                  MioSpacing.sm,
                  MioSpacing.sm,
                  MioSpacing.xs,
                ),
                child: Text(
                  anime.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: MioSpacing.sm),
                child: Wrap(
                  spacing: MioSpacing.xs,
                  children: <Widget>[
                    if (anime.score != null)
                      Chip(label: Text(anime.score!.toStringAsFixed(1))),
                    Chip(label: Text(anime.sourceLabel)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({
    required this.state,
    required this.onRetry,
    required this.onLoad,
  });
  final DiscoverState state;
  final VoidCallback onRetry;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    if (state.status == DiscoverStatus.loadingMore) {
      // The cards themselves are drawn by the grid above; this is the line that
      // names what they are waiting for.
      return Padding(
        padding: const EdgeInsets.only(bottom: MioSpacing.lg),
        child: Center(
          child: Text('正在加载更多…', style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    if (state.status == DiscoverStatus.loadMoreError) {
      return Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('加载更多失败，重试'),
        ),
      );
    }
    if (!state.hasMore) {
      return const SizedBox(height: MioSpacing.xl);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: MioSpacing.xl),
        child: FilledButton.tonal(onPressed: onLoad, child: const Text('加载更多')),
      ),
    );
  }
}
