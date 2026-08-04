import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/library/application/library_providers.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';
import 'package:mio_ani/src/features/library/domain/library_query.dart';

final class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key, this.initialQuery = const LibraryQuery()});
  final LibraryQuery initialQuery;
  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

final class _LibraryPageState extends ConsumerState<LibraryPage> {
  late LibraryQuery _query;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery.normalized();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(libraryStreamProvider(_query));
    final repository = ref.watch(libraryRepositoryProvider);
    final controller = ref.read(libraryControllerProvider(_query).notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的追番库'),
        actions: <Widget>[
          IconButton(
            tooltip: '身份候选与冲突',
            icon: Badge(
              isLabelVisible: repository.pendingCandidates.isNotEmpty,
              label: Text(repository.pendingCandidates.length.toString()),
              child: const Icon(Icons.rule),
            ),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const IdentityReviewPage(),
              ),
            ),
          ),
          IconButton(
            tooltip: '添加本地作品',
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, controller),
          ),
          PopupMenuButton<String>(
            tooltip: '数据清理',
            onSelected: (value) => _cleanupAction(context, value),
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'cache',
                child: Text('清理公共缓存'),
              ),
              const PopupMenuItem<String>(
                value: 'user',
                child: Text('清除 Flutter 用户数据'),
              ),
              if (kIsWeb)
                const PopupMenuItem<String>(
                  value: 'vue',
                  child: Text('删除 Vue 旧键'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _GroupBar(
            query: _query,
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('读取追番库失败：$error')),
              data: (records) => records.isEmpty
                  ? const _EmptyLibrary()
                  : ListView.separated(
                      key: const PageStorageKey<String>('library-list'),
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _LibraryCard(
                        record: records[index],
                        onOpen: () => _openDetails(context, records[index]),
                        onStatusChanged: (status) => controller.setStatus(
                          records[index].entry.identityId,
                          status,
                        ),
                        onProgressChanged: (value) => controller.setProgress(
                          records[index].entry.identityId,
                          value,
                        ),
                        onRemove: () =>
                            controller.remove(records[index].entry.identityId),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, LibraryRecord record) {
    final source = record.identity.sources.isEmpty
        ? null
        : record.identity.sources.first;
    if (source == null) return;
    AnimeDetailRouteData(id: source.sourceId.value).push<void>(context);
  }

  Future<void> _showAddDialog(
    BuildContext context,
    LibraryController controller,
  ) async {
    final idController = TextEditingController();
    final titleController = TextEditingController();
    final result = await showDialog<(AnimeSourceId, String)?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加本地作品'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: '来源 ID',
                hintText: '例如 bgm-2 或 anilist-20',
              ),
            ),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '展示标题'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final id = AnimeSourceId.tryParse(idController.text);
              final title = titleController.text.trim();
              if (id == null || title.isEmpty) return;
              Navigator.pop(context, (id, title));
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
    idController.dispose();
    titleController.dispose();
    if (!mounted || result == null) return;
    await controller.addLocal(
      SourceObservation(sourceId: result.$1, title: result.$2),
    );
    if (!mounted || !context.mounted) return;
    final state = ref.read(libraryControllerProvider(_query));
    if (state.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
    }
  }

  Future<void> _cleanupAction(BuildContext context, String action) async {
    final message = switch (action) {
      'cache' => '只清理公共缓存，不会删除本地追番库。',
      'user' => '将清除 Flutter 用户数据。当前没有备份恢复功能，MioAni 无法撤销。',
      'vue' => '将删除浏览器中的 Vue 旧键；此操作影响旧数据回滚，请确认后继续。',
      _ => '',
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认数据清理'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repository = ref.read(libraryRepositoryProvider);
    try {
      switch (action) {
        case 'cache':
          await repository.clearPublicCache();
        case 'user':
          await repository.clearFlutterUserData();
        case 'vue':
          await repository.deleteVueLegacyKeys();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('清理操作已完成。')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

final class _GroupBar extends StatelessWidget {
  const _GroupBar({required this.query, required this.onChanged});
  final LibraryQuery query;
  final ValueChanged<LibraryQuery> onChanged;
  @override
  Widget build(BuildContext context) {
    final chips = LibraryQueryGroup.values
        .map((group) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(group.label),
              selected: query.group == group,
              onSelected: (_) => onChanged(
                LibraryQuery(
                  group: group,
                  sort: query.sort,
                  query: query.query,
                  descending: query.descending,
                ),
              ),
            ),
          );
        })
        .toList(growable: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: chips),
    );
  }
}

final class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.record,
    required this.onOpen,
    required this.onStatusChanged,
    required this.onProgressChanged,
    required this.onRemove,
  });
  final LibraryRecord record;
  final VoidCallback onOpen;
  final ValueChanged<LibraryWatchStatus> onStatusChanged;
  final ValueChanged<int> onProgressChanged;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final entry = record.entry;
    final total = entry.totalEpisodes;
    return Card(
      child: ListTile(
        isThreeLine: true,
        onTap: onOpen,
        title: Text(record.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 6,
              children: record.identity.sources
                  .map((source) => Chip(label: Text(source.sourceId.value)))
                  .toList(),
            ),
            Row(
              children: <Widget>[
                DropdownButton<LibraryWatchStatus>(
                  value: entry.status,
                  items: LibraryWatchStatus.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status != null) onStatusChanged(status);
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: '减少进度',
                  onPressed: entry.watched > 0
                      ? () => onProgressChanged(entry.watched - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Text('${entry.watched}${total == null ? '' : ' / $total'}'),
                IconButton(
                  tooltip: '增加进度',
                  onPressed: total == null || entry.watched < total
                      ? () => onProgressChanged(entry.watched + 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          tooltip: '移除',
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  static String _statusLabel(LibraryWatchStatus status) => switch (status) {
    LibraryWatchStatus.watching => '在看',
    LibraryWatchStatus.completed => '看过',
    LibraryWatchStatus.planned => '想看',
    LibraryWatchStatus.paused => '暂停',
    LibraryWatchStatus.dropped => '弃置',
  };
}

final class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('还没有本地追番，点击右上角添加作品。'));
}

final class IdentityReviewPage extends ConsumerStatefulWidget {
  const IdentityReviewPage({super.key});
  @override
  ConsumerState<IdentityReviewPage> createState() => _IdentityReviewPageState();
}

final class _IdentityReviewPageState extends ConsumerState<IdentityReviewPage> {
  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(libraryRepositoryProvider);
    final candidates = repository.pendingCandidates;
    return Scaffold(
      appBar: AppBar(title: const Text('身份候选与冲突')),
      body: candidates.isEmpty
          ? const Center(child: Text('暂无待评审候选。'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${candidate.left.title} ↔ ${candidate.right.title}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(candidate.evidence.explanation),
                        Text(
                          '来源：${candidate.left.sourceId.value}、${candidate.right.sourceId.value}',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            FilledButton(
                              onPressed: () async {
                                await repository.confirmCandidate(candidate.id);
                                if (mounted) setState(() {});
                              },
                              child: const Text('确认关联'),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                await repository.keepSeparate(candidate.id);
                                if (mounted) setState(() {});
                              },
                              child: const Text('保持分开'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await repository.ignoreCandidate(candidate.id);
                                if (mounted) setState(() {});
                              },
                              child: const Text('忽略'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
