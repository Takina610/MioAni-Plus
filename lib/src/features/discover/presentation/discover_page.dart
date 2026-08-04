import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/discover/application/discover_providers.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query.dart';
import 'package:mio_ani/src/features/discover/domain/discover_query_codec.dart';
import 'package:mio_ani/src/features/discover/domain/discover_state.dart';
import 'package:mio_ani/src/shared/design_system/mio_breakpoints.dart';
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
    }
  }

  @override
  void dispose() {
    _routeDebounce?.cancel();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverControllerProvider(_query));
    final width = MediaQuery.sizeOf(context).width;
    final windowClass = MioBreakpoints.windowClassFor(width);
    final filters = _FilterSummary(query: _query, onClear: _clearFilters);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(discoverControllerProvider(_query).notifier).refresh();
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
                const SliverFillRemaining(
                  child: MioStateView.loading(label: '正在搜索…'),
                )
              else if (state.status == DiscoverStatus.firstPageError &&
                  state.items.isEmpty)
                SliverFillRemaining(
                  child: MioStateView.failure(
                    failure: state.failure ?? const UnknownFailure(),
                    onRetry: () => ref
                        .read(discoverControllerProvider(_query).notifier)
                        .retry(),
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
                      (context, index) => _AnimeCard(anime: state.items[index]),
                      childCount: state.items.length,
                    ),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: windowClass == MioWindowClass.expanded
                          ? 220
                          : 180,
                      mainAxisExtent: 350,
                      crossAxisSpacing: MioSpacing.md,
                      mainAxisSpacing: MioSpacing.md,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _LoadMore(
                    state: state,
                    onRetry: () => ref
                        .read(discoverControllerProvider(_query).notifier)
                        .loadMore(),
                    onLoad: () => ref
                        .read(discoverControllerProvider(_query).notifier)
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
          const Text('基础外壳已就绪，内容将在后续纵向切片接入。'),
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
        .read(discoverControllerProvider(_query).notifier)
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

class _AnimeCard extends StatelessWidget {
  const _AnimeCard({required this.anime});
  final AnimeSummary anime;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: anime.title,
      child: InkWell(
        onTap: () =>
            AnimeDetailRouteData(id: anime.id.value).push<void>(context),
        borderRadius: BorderRadius.circular(MioRadii.md),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: 230,
                width: double.infinity,
                child: MioImage(
                  imageUrl: anime.imageUrl,
                  semanticLabel: anime.title,
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
      return const Padding(
        padding: EdgeInsets.all(MioSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
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
