import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/people/application/people_providers.dart';
import 'package:mio_ani/src/features/people/data/people_repository.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';
import 'package:mio_ani/src/features/people/presentation/person_detail_page.dart';

final class _FakePeopleRepository implements PeopleRepository {
  int profileCalls = 0;
  @override
  Future<PersonProfile> fetchProfile(
    PersonSourceId id, {
    bool forceRefresh = false,
  }) async {
    profileCalls++;
    return PersonProfile(
      id: id,
      name: id.isCharacter ? '角色 A' : '人物 B',
      aliases: const <String>['别名'],
      summary: '简介',
      gender: '女',
    );
  }

  @override
  Future<({List<PersonWork> items, bool hasMore})> fetchWorks(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  }) async => (items: const <PersonWork>[], hasMore: false);
  @override
  Future<({List<VoiceRole> items, bool hasMore})> fetchVoiceRoles(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  }) async => (items: const <VoiceRole>[], hasMore: false);
  @override
  Future<({List<PersonComment> items, bool hasMore})> fetchComments(
    PersonSourceId id,
    int page, {
    bool forceRefresh = false,
  }) async => (items: const <PersonComment>[], hasMore: false);
}

void main() {
  testWidgets('character detail loads profile and keeps section boundaries', (
    tester,
  ) async {
    final repository = _FakePeopleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [peopleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: CharacterDetailPage(sourceId: 'bgm-char-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('角色详情'), findsOneWidget);
    expect(find.text('bgm-char-1'), findsOneWidget);
    expect(find.text('角色 A'), findsOneWidget);
    expect(find.text('相关作品'), findsOneWidget);
    expect(find.text('评论'), findsOneWidget);
    expect(repository.profileCalls, 1);
  });

  testWidgets('person detail supports wide layout and direct URL IDs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakePeopleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [peopleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: PersonDetailPage(sourceId: 'anilist-staff-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('人物详情'), findsOneWidget);
    expect(find.text('anilist-staff-2'), findsOneWidget);
    expect(find.text('人物 B'), findsOneWidget);
  });

  testWidgets('invalid people IDs do not call the repository', (tester) async {
    final repository = _FakePeopleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [peopleRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PersonDetailPage(sourceId: 'invalid')),
      ),
    );
    await tester.pump();
    expect(find.text('页面不存在'), findsOneWidget);
    expect(repository.profileCalls, 0);
  });
}
