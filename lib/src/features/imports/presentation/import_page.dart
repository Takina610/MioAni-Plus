import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/features/imports/application/import_providers.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';

final class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

final class _ImportPageState extends ConsumerState<ImportPage> {
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importControllerProvider);
    final controller = ref.read(importControllerProvider.notifier);
    final preview = state.preview;
    return Scaffold(
      appBar: AppBar(title: const Text('导入公开收藏')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text('仅读取 Bangumi 或 AniList 的公开收藏，不需要登录、Token 或远端写回。'),
          const SizedBox(height: 16),
          DropdownButtonFormField<ImportSource>(
            key: ValueKey<ImportSource>(state.source),
            initialValue: state.source,
            decoration: const InputDecoration(
              labelText: '公开来源',
              border: OutlineInputBorder(),
            ),
            items: const <DropdownMenuItem<ImportSource>>[
              DropdownMenuItem(
                value: ImportSource.bangumi,
                child: Text('Bangumi'),
              ),
              DropdownMenuItem(
                value: ImportSource.anilist,
                child: Text('AniList'),
              ),
            ],
            onChanged: state.isBusy
                ? null
                : (value) {
                    if (value != null) controller.setSource(value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            enabled: !state.isBusy,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '公开用户名',
              hintText: '只作为查询输入，不作为账号主键',
              border: OutlineInputBorder(),
            ),
            onChanged: controller.setInput,
            onSubmitted: (_) => controller.start(),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: state.isBusy ? controller.cancel : controller.start,
                icon: Icon(state.isBusy ? Icons.stop : Icons.download),
                label: Text(state.isBusy ? '取消读取' : '读取公开收藏'),
              ),
              if (state.stage == ImportStage.previewStale) ...<Widget>[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: controller.start,
                  child: const Text('重新生成预览'),
                ),
              ],
            ],
          ),
          if (state.progress != null) ...<Widget>[
            const SizedBox(height: 16),
            Semantics(
              label: state.progress!.message ?? '导入进度',
              value: state.progress!.fraction == null
                  ? '${state.progress!.itemsParsed} 条'
                  : '${(state.progress!.fraction! * 100).round()}%',
              child: LinearProgressIndicator(value: state.progress!.fraction),
            ),
            const SizedBox(height: 8),
            Text(state.progress!.message ?? '正在读取公开收藏'),
          ],
          if (state.error != null) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(state.error!),
              ),
            ),
          ],
          if (state.profile != null) ...<Widget>[
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(state.profile!.displayName),
              subtitle: Text(
                '稳定账号 ID：${state.profile!.key.stableUserId}（来源：${state.profile!.key.source.name}）',
              ),
            ),
          ],
          if (preview != null) ...<Widget>[
            const Divider(height: 24),
            Text('导入预览', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _PreviewSummary(preview: preview),
            const SizedBox(height: 12),
            if (preview.accountChangeRequiresConfirmation)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.warning_amber),
                  title: Text('检测到同来源其他稳定账号'),
                  subtitle: Text('确认后会合并到本地库，不会删除旧账号条目。'),
                ),
              ),
            FilledButton(
              onPressed: preview.canCommit && !state.isBusy
                  ? () => _commit(context, preview, controller)
                  : null,
              child: const Text('确认并提交本批次'),
            ),
          ],
          if (state.batch != null) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(
                  state.batch!.isUndone ? Icons.undo : Icons.check_circle,
                ),
                title: Text(state.batch!.isUndone ? '批次已撤销' : '导入批次已完成'),
                subtitle: Text(
                  '${state.batch!.itemCount} 条，fingerprint ${state.batch!.fingerprint}',
                ),
                trailing: state.batch!.isUndone
                    ? null
                    : TextButton(
                        onPressed: () =>
                            controller.prepareUndo(state.batch!.id),
                        child: const Text('预览撤销'),
                      ),
              ),
            ),
          ],
          if (state.history.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text('导入历史', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...state.history.map(
              (batch) => ListTile(
                dense: true,
                title: Text(batch.profile.displayName),
                subtitle: Text(
                  '${batch.profile.key.source.name} · ${batch.itemCount} 条 · ${batch.createdAt.toLocal()}',
                ),
                trailing: batch.isUndone
                    ? const Text('已撤销')
                    : TextButton(
                        onPressed: () => controller.prepareUndo(batch.id),
                        child: const Text('撤销预览'),
                      ),
              ),
            ),
          ],
          if (state.undoPreview != null) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('撤销预览'),
                subtitle: Text(
                  '可移除 ${state.undoPreview!.removable.length} 条，保护 ${state.undoPreview!.protectedContributions.length} 条。',
                ),
                trailing: FilledButton(
                  onPressed: state.undoPreview!.canUndo
                      ? controller.undo
                      : null,
                  child: const Text('执行撤销'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _commit(
    BuildContext context,
    ImportPreview preview,
    ImportController controller,
  ) async {
    final confirm = preview.accountChangeRequiresConfirmation
        ? await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('确认换账号导入'),
              content: const Text('同来源稳定账号不同。继续后只会合并本地数据，不会删除旧账号条目。'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确认导入'),
                ),
              ],
            ),
          )
        : true;
    if (confirm == true && mounted) {
      await controller.commit(confirmAccountChange: confirm ?? false);
    }
  }
}

final class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.preview});

  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final counts = preview.counts;
    final values = <String, int>{
      '新增': counts.added,
      '观察更新': counts.observationUpdated,
      '确定关联': counts.linked,
      '身份候选': counts.identityCandidates,
      '状态冲突': counts.stateConflicts,
      '跳过': counts.skipped,
      '远端未出现': counts.remoteMissing,
      '无变化': counts.unchanged,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.entries
          .map((entry) => Chip(label: Text('${entry.key} ${entry.value}')))
          .toList(growable: false),
    );
  }
}
