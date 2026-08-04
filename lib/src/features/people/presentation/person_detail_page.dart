import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/mio_image.dart';
import 'package:mio_ani/src/features/people/application/people_providers.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class PersonDetailPage extends StatelessWidget {
  const PersonDetailPage({required this.sourceId, super.key});
  final String sourceId;
  @override
  Widget build(BuildContext context) =>
      _PeopleDetailPage(sourceId: sourceId, kind: PersonEntityKind.person);
}

class CharacterDetailPage extends StatelessWidget {
  const CharacterDetailPage({required this.sourceId, super.key});
  final String sourceId;
  @override
  Widget build(BuildContext context) =>
      _PeopleDetailPage(sourceId: sourceId, kind: PersonEntityKind.character);
}

class _PeopleDetailPage extends ConsumerStatefulWidget {
  const _PeopleDetailPage({required this.sourceId, required this.kind});
  final String sourceId;
  final PersonEntityKind kind;
  @override
  ConsumerState<_PeopleDetailPage> createState() => _PeopleDetailPageState();
}

class _PeopleDetailPageState extends ConsumerState<_PeopleDetailPage> {
  PersonSourceId? _id;
  @override
  void initState() {
    super.initState();
    _id = PersonSourceId.tryParse(widget.sourceId);
    if (_id != null &&
        _id!.kind != widget.kind &&
        !(widget.kind == PersonEntityKind.person && _id!.isPerson)) {
      _id = null;
    }
    if (_id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          ref.read(peopleControllerProvider(_id!).notifier).loadProfile(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _id;
    final title = widget.kind == PersonEntityKind.character ? '角色详情' : '人物详情';
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: MioStateView.notFound(message: '无法识别人物 ID：${widget.sourceId}'),
      );
    }
    final state = ref.watch(peopleControllerProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text(widget.sourceId),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _PeopleContent(
          id: id,
          state: state,
          isCharacter: widget.kind == PersonEntityKind.character,
          onRetry: () => ref
              .read(peopleControllerProvider(id).notifier)
              .retry(PeopleSection.profile),
        ),
      ),
    );
  }
}

class _PeopleContent extends StatelessWidget {
  const _PeopleContent({
    required this.id,
    required this.state,
    required this.isCharacter,
    required this.onRetry,
  });
  final PersonSourceId id;
  final PeopleDetailState state;
  final bool isCharacter;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final profile = state.profile.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final header = _ProfileHeader(
          id: id,
          profile: profile,
          state: state.profile,
          onRetry: onRetry,
          wide: wide,
        );
        return ListView(
          padding: const EdgeInsets.all(MioSpacing.lg),
          children: <Widget>[
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: MioSizes.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    header,
                    const SizedBox(height: MioSpacing.lg),
                    _SectionCard<PersonWork>(
                      title: '相关作品',
                      state: state.works,
                      emptyLabel: '暂无相关作品',
                      itemBuilder: (item) => ListTile(
                        title: Text(item.title),
                        subtitle: item.role == null ? null : Text(item.role!),
                        leading: SizedBox(
                          width: 48,
                          height: 64,
                          child: MioImage(
                            imageUrl: item.imageUrl,
                            semanticLabel: item.title,
                          ),
                        ),
                        onTap: () => unawaited(
                          AnimeDetailRouteData(
                            id: item.animeId.value,
                          ).push<void>(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: MioSpacing.md),
                    _SectionCard<VoiceRole>(
                      title: isCharacter ? '声优与出演角色' : '出演角色',
                      state: state.voiceRoles,
                      emptyLabel: '暂无出演角色',
                      itemBuilder: (item) => ListTile(
                        title: Text(item.characterName),
                        subtitle: item.personName == null
                            ? null
                            : Text(item.personName!),
                        onTap: item.personId == null
                            ? null
                            : () => unawaited(
                                PersonDetailRouteData(
                                  id: item.personId!.value,
                                ).push<void>(context),
                              ),
                      ),
                    ),
                    const SizedBox(height: MioSpacing.md),
                    _CommentsCard(state: state.comments),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.id,
    required this.profile,
    required this.state,
    required this.onRetry,
    required this.wide,
  });
  final PersonSourceId id;
  final PersonProfile? profile;
  final SectionState<PersonProfile> state;
  final VoidCallback onRetry;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final name = profile?.name ?? '人物资料加载中';
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(name, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: MioSpacing.xs),
        if (profile?.aliases.isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: MioSpacing.sm),
          Text('别名：${profile!.aliases.join('、')}'),
        ],
        if (profile?.summary case final summary?) ...<Widget>[
          const SizedBox(height: MioSpacing.md),
          SelectableText(summary),
        ],
        if (profile != null) ...<Widget>[
          const SizedBox(height: MioSpacing.md),
          Wrap(
            spacing: MioSpacing.xs,
            runSpacing: MioSpacing.xs,
            children: <Widget>[
              if (profile!.gender case final gender?) Chip(label: Text(gender)),
              if (profile!.bloodType case final blood?)
                Chip(label: Text('血型 $blood')),
              if (profile!.birthDate case final date?)
                Chip(label: Text('生日 ${date.year}-${date.month}-${date.day}')),
              ...profile!.careers.map((career) => Chip(label: Text(career))),
            ],
          ),
        ],
        if (state.status == SectionStatus.loading)
          const Padding(
            padding: EdgeInsets.only(top: MioSpacing.md),
            child: LinearProgressIndicator(),
          ),
        if (state.status == SectionStatus.errorEmpty) ...<Widget>[
          const SizedBox(height: MioSpacing.md),
          Text(
            state.error is AppFailure
                ? (state.error! as AppFailure).userMessage
                : '资料加载失败',
          ),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ],
    );
    final image = SizedBox(
      width: wide ? 180 : double.infinity,
      height: wide ? 250 : 280,
      child: MioImage(imageUrl: profile?.imageUrl, semanticLabel: '$name 头像'),
    );
    return wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              image,
              const SizedBox(width: MioSpacing.lg),
              Expanded(child: text),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              image,
              const SizedBox(height: MioSpacing.md),
              text,
            ],
          );
  }
}

class _SectionCard<T> extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.state,
    required this.emptyLabel,
    required this.itemBuilder,
  });
  final String title;
  final SectionState<List<T>> state;
  final String emptyLabel;
  final Widget Function(T item) itemBuilder;
  @override
  Widget build(BuildContext context) {
    final items = state.value ?? const <Never>[];
    final content = <Widget>[
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ];
    if (state.status == SectionStatus.loading) {
      content.add(
        const Padding(
          padding: EdgeInsets.all(MioSpacing.md),
          child: LinearProgressIndicator(),
        ),
      );
    }
    if (state.status == SectionStatus.errorEmpty) {
      content.add(const Text('分区加载失败'));
    }
    if (items.isEmpty && state.status != SectionStatus.loading) {
      content.add(Text(emptyLabel));
    }
    content.addAll(items.map(itemBuilder));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  const _CommentsCard({required this.state});
  final SectionState<List<PersonComment>> state;
  @override
  Widget build(BuildContext context) {
    final comments = state.value ?? const <PersonComment>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('评论', style: Theme.of(context).textTheme.titleLarge),
            if (comments.isEmpty) const Text('暂无评论'),
            ...comments.map(
              (comment) => ListTile(
                title: Text(comment.userName),
                subtitle: Text(comment.body),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
