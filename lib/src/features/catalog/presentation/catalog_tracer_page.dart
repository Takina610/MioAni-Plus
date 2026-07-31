import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class CatalogTracerPage extends ConsumerWidget {
  const CatalogTracerPage({super.key});

  static const pageStorageKey = PageStorageKey<String>('bangumi-catalog');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogStreamProvider);
    return Scaffold(
      body: SafeArea(
        child: catalog.when(
          loading: () => const MioStateView.loading(label: '正在连接 Bangumi'),
          error: (error, _) => MioStateView.failure(
            failure: _failureFrom(error),
            onRetry: () => _requestRefresh(ref),
          ),
          data: (snapshot) => _CatalogContent(
            snapshot: snapshot,
            onRefresh: () async {
              _requestRefresh(ref);
              await ref.read(catalogStreamProvider.future);
            },
          ),
        ),
      ),
    );
  }

  AppFailure _failureFrom(Object error) {
    return error is AppFailure ? error : const UnknownFailure();
  }

  void _requestRefresh(WidgetRef ref) {
    final notifier = ref.read(catalogRefreshGenerationProvider.notifier);
    notifier.state += 1;
  }
}

class _CatalogContent extends StatelessWidget {
  const _CatalogContent({required this.snapshot, required this.onRefresh});

  final CatalogSnapshot<List<AnimeSummary>> snapshot;
  final Future<void> Function() onRefresh;

  static const double _compactBreakpoint = 520;
  static const double _mediumBreakpoint = 840;
  static const double _wideBreakpoint = 1180;
  static const double _largeTextScaleThreshold = 1.5;
  static const double _defaultCardExtent = 380;
  static const double _largeTextCardExtent = 440;

  @override
  Widget build(BuildContext context) {
    if (snapshot.value.isEmpty) {
      return MioStateView.empty(
        title: '本期目录为空',
        message: 'Bangumi 暂时没有返回可展示的动画。',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          < _compactBreakpoint => 1,
          < _mediumBreakpoint => 2,
          < _wideBreakpoint => 3,
          _ => 4,
        };
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final itemExtent = textScale > _largeTextScaleThreshold
            ? _largeTextCardExtent
            : _defaultCardExtent;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            key: CatalogTracerPage.pageStorageKey,
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MioSpacing.lg,
                  MioSpacing.xl,
                  MioSpacing.lg,
                  MioSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: _CatalogHeader(snapshot: snapshot),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MioSpacing.lg,
                  0,
                  MioSpacing.lg,
                  MioSpacing.xl,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: MioSpacing.md,
                    crossAxisSpacing: MioSpacing.md,
                    mainAxisExtent: itemExtent,
                  ),
                  itemCount: snapshot.value.length,
                  itemBuilder: (context, index) {
                    return AnimeCatalogCard(anime: snapshot.value[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({required this.snapshot});

  final CatalogSnapshot<List<AnimeSummary>> snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('本周动画目录', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: MioSpacing.xs),
        Text(
          '来自 Bangumi 的公开数据 · ${snapshot.value.length} 部作品',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (snapshot.isStale) ...<Widget>[
          const SizedBox(height: MioSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(MioSpacing.sm),
            decoration: BoxDecoration(
              color: MioColors.surfaceHigh,
              borderRadius: BorderRadius.circular(MioRadii.sm),
            ),
            child: Text(
              snapshot.refreshFailure == null
                  ? '正在更新缓存内容…'
                  : '当前显示离线缓存，内容更新时间：${_formatTime(snapshot.fetchedAt)}',
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class AnimeCatalogCard extends StatelessWidget {
  const AnimeCatalogCard({required this.anime, super.key});

  final AnimeSummary anime;

  @override
  Widget build(BuildContext context) {
    final displayTitle = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: MioColors.surface,
      child: InkWell(
        onTap: () {
          unawaited(
            AnimeDetailRouteData(id: anime.id.value).push<void>(context),
          );
        },
        child: Semantics(
          button: true,
          label: '查看 $displayTitle 详情',
          child: Padding(
            padding: const EdgeInsets.all(MioSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: MioImage(
                      imageUrl: anime.imageUrl,
                      semanticLabel: '$displayTitle 海报',
                    ),
                  ),
                ),
                const SizedBox(height: MioSpacing.sm),
                Text(
                  displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: MioSpacing.xs),
                Wrap(
                  spacing: MioSpacing.sm,
                  runSpacing: MioSpacing.xxs,
                  children: <Widget>[
                    Text(anime.sourceLabel),
                    if (anime.score case final score?)
                      Text('★ ${score.toStringAsFixed(1)}'),
                    if (anime.airDate case final date?) Text('${date.year}'),
                  ],
                ),
                if (anime.summary case final summary?) ...<Widget>[
                  const SizedBox(height: MioSpacing.xs),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
