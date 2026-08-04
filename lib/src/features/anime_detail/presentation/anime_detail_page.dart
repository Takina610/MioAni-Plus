import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_detail_providers.dart';
import 'package:mio_ani/src/features/anime_detail/domain/anime_detail_sections.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/catalog/domain/catalog_snapshot.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class AnimeDetailPage extends ConsumerWidget {
  const AnimeDetailPage({required this.sourceId, super.key});

  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = AnimeSourceId.tryParse(sourceId);
    return Scaffold(
      appBar: AppBar(title: const Text('动画详情')),
      body: SafeArea(
        child: id == null
            ? MioStateView.notFound(message: '无法识别动画 ID：$sourceId')
            : id.source != AnimeSource.bangumi
            ? MioStateView.notFound(message: '该来源的动画详情将在后续版本提供')
            : ref
                  .watch(animeDetailStreamProvider(id))
                  .when(
                    loading: () =>
                        const MioStateView.loading(label: '正在加载动画详情'),
                    error: (error, _) => error is NotFoundFailure
                        ? MioStateView.notFound(message: 'Bangumi 中不存在该动画')
                        : MioStateView.failure(
                            failure: error is AppFailure
                                ? error
                                : const UnknownFailure(),
                            onRetry: () => _requestRefresh(ref, id),
                          ),
                    data: (snapshot) => _AnimeDetailContent(
                      snapshot: snapshot,
                      onRetry: () => _requestRefresh(ref, id),
                    ),
                  ),
      ),
    );
  }

  void _requestRefresh(WidgetRef ref, AnimeSourceId id) {
    final notifier = ref.read(detailRefreshGenerationProvider(id).notifier);
    notifier.state += 1;
  }
}

class _AnimeDetailContent extends StatelessWidget {
  const _AnimeDetailContent({required this.snapshot, required this.onRetry});

  final CatalogSnapshot<AnimeDetail> snapshot;
  final VoidCallback onRetry;

  static const double _wideBreakpoint = 760;
  static const double _widePosterWidth = 280;
  static const double _widePosterHeight = 400;
  static const double _compactPosterHeight = 360;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;
        final poster = SizedBox(
          width: wide ? _widePosterWidth : double.infinity,
          height: wide ? _widePosterHeight : _compactPosterHeight,
          child: MioImage(
            imageUrl: snapshot.value.imageUrl,
            semanticLabel:
                '${snapshot.value.title.isEmpty ? '标题暂缺' : snapshot.value.title} 海报',
          ),
        );
        final information = _AnimeInformation(anime: snapshot.value);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(MioSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: MioSizes.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (snapshot.isStale)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: MioSpacing.md),
                      padding: const EdgeInsets.all(MioSpacing.sm),
                      decoration: BoxDecoration(
                        color: MioColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(MioRadii.sm),
                      ),
                      child: switch (snapshot.refreshFailure) {
                        final failure? => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('当前显示已缓存的详情，刷新失败：${failure.userMessage}'),
                            const SizedBox(height: MioSpacing.xs),
                            TextButton(
                              onPressed: onRetry,
                              child: const Text('重试更新'),
                            ),
                          ],
                        ),
                        null => const Text('当前显示已缓存的详情，正在联网更新。'),
                      },
                    ),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        poster,
                        const SizedBox(width: MioSpacing.xl),
                        Expanded(child: information),
                      ],
                    )
                  else ...<Widget>[
                    poster,
                    const SizedBox(height: MioSpacing.lg),
                    information,
                  ],
                  const SizedBox(height: MioSpacing.xl),
                  _AnimeExtendedSections(animeId: snapshot.value.id),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimeInformation extends StatelessWidget {
  const _AnimeInformation({required this.anime});

  final AnimeDetail anime;

  @override
  Widget build(BuildContext context) {
    final displayTitle = anime.title.isEmpty ? '标题暂缺' : anime.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(displayTitle, style: Theme.of(context).textTheme.headlineLarge),
        if (anime.sourceTitle.isNotEmpty &&
            anime.sourceTitle != anime.title) ...<Widget>[
          const SizedBox(height: MioSpacing.xs),
          SelectableText(
            anime.sourceTitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: MioSpacing.md),
        Wrap(
          spacing: MioSpacing.sm,
          runSpacing: MioSpacing.sm,
          children: <Widget>[
            const Chip(label: Text('Bangumi')),
            if (anime.score case final score?)
              Chip(label: Text('评分 ${score.toStringAsFixed(1)}')),
            if (anime.rank case final rank?) Chip(label: Text('排名 #$rank')),
            if (anime.episodes case final episodes?)
              Chip(label: Text('$episodes 集')),
            if (anime.format case final format?) Chip(label: Text(format)),
            if (anime.airDate case final date?)
              Chip(label: Text('${date.year}')),
          ],
        ),
        if (anime.tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: MioSpacing.md),
          Wrap(
            spacing: MioSpacing.xs,
            runSpacing: MioSpacing.xs,
            children: anime.tags.map((tag) => Chip(label: Text(tag))).toList(),
          ),
        ],
        const SizedBox(height: MioSpacing.lg),
        Text('剧情简介', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: MioSpacing.xs),
        SelectableText(
          anime.summary ?? 'Bangumi 暂未提供剧情简介。',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _AnimeExtendedSections extends ConsumerStatefulWidget {
  const _AnimeExtendedSections({required this.animeId});
  final AnimeSourceId animeId;
  @override
  ConsumerState<_AnimeExtendedSections> createState() =>
      _AnimeExtendedSectionsState();
}

class _AnimeExtendedSectionsState
    extends ConsumerState<_AnimeExtendedSections> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(MioSpacing.md),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '关联作品、角色/声优、制作人员与翻译',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _expanded = true),
                child: const Text('加载扩展资料'),
              ),
            ],
          ),
        ),
      );
    }
    final relations = ref.watch(animeRelationsProvider(widget.animeId));
    final characters = ref.watch(animeCharactersProvider(widget.animeId));
    final staff = ref.watch(animeStaffProvider(widget.animeId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AnimeSection<AnimeRelation>(
          title: '关联作品',
          value: relations,
          onRetry: () => refreshAnimeRelations(ref, widget.animeId),
          itemBuilder: (item) => ListTile(
            title: Text(item.title),
            subtitle: item.relation == null ? null : Text(item.relation!),
            leading: SizedBox(
              width: 48,
              height: 64,
              child: MioImage(
                imageUrl: item.imageUrl,
                semanticLabel: item.title,
              ),
            ),
            onTap: () => unawaited(
              AnimeDetailRouteData(id: item.animeId.value).push<void>(context),
            ),
          ),
        ),
        const SizedBox(height: MioSpacing.md),
        _AnimeSection<AnimeCharacterCredit>(
          title: '角色/声优',
          value: characters,
          onRetry: () => refreshAnimeCharacters(ref, widget.animeId),
          itemBuilder: (item) => ListTile(
            title: Text(item.name),
            subtitle: item.voiceActorName == null
                ? item.role == null
                      ? null
                      : Text(item.role!)
                : Text(item.voiceActorName!),
            leading: SizedBox(
              width: 48,
              height: 64,
              child: MioImage(
                imageUrl: item.imageUrl,
                semanticLabel: item.name,
              ),
            ),
            onTap: () => unawaited(
              CharacterDetailRouteData(
                id: item.characterId.value,
              ).push<void>(context),
            ),
          ),
        ),
        const SizedBox(height: MioSpacing.md),
        _AnimeSection<AnimeStaffCredit>(
          title: '制作人员',
          value: staff,
          onRetry: () => refreshAnimeStaff(ref, widget.animeId),
          itemBuilder: (item) => ListTile(
            title: Text(item.name),
            subtitle: item.role == null ? null : Text(item.role!),
            leading: SizedBox(
              width: 48,
              height: 64,
              child: MioImage(
                imageUrl: item.imageUrl,
                semanticLabel: item.name,
              ),
            ),
            onTap: () => unawaited(
              PersonDetailRouteData(
                id: item.personId.value,
              ).push<void>(context),
            ),
          ),
        ),
        const SizedBox(height: MioSpacing.md),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(MioSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('翻译', style: TextStyle(fontSize: 18)),
                SizedBox(height: MioSpacing.xs),
                Text('当前来源暂无可用翻译。'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimeSection<T> extends StatelessWidget {
  const _AnimeSection({
    required this.title,
    required this.value,
    required this.onRetry,
    required this.itemBuilder,
  });
  final String title;
  final AsyncValue<List<T>> value;
  final VoidCallback onRetry;
  final Widget Function(T item) itemBuilder;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            value.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(MioSpacing.md),
                child: LinearProgressIndicator(),
              ),
              error: (error, _) => Row(
                children: <Widget>[
                  const Expanded(child: Text('该分区加载失败，主体信息仍可使用。')),
                  TextButton(onPressed: onRetry, child: const Text('重试')),
                ],
              ),
              data: (items) => items.isEmpty
                  ? const Text('暂无内容')
                  : Column(
                      children: items.map(itemBuilder).toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
