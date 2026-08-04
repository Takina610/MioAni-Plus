import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/people/data/anilist_people_source.dart';
import 'package:mio_ani/src/features/people/data/bangumi_people_source.dart';
import 'package:mio_ani/src/features/people/data/people_cache_store.dart';
import 'package:mio_ani/src/features/people/data/people_repository.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';
import 'package:mio_ani/src/features/people/domain/person_source_id.dart';

enum PeopleSection { profile, works, voiceRoles, comments }

final peopleRepositoryProvider = Provider<PeopleRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final coordinator = ref.watch(requestCoordinatorProvider);
  return PeopleRepositoryImpl(
    bangumi: BangumiPeopleSource(dio: dio, coordinator: coordinator),
    anilist: AniListPeopleSource(dio: dio, coordinator: coordinator),
    cache: MemoryPeopleCacheStore(),
    now: DateTime.now,
  );
});

final class PeopleDetailState {
  const PeopleDetailState({
    required this.id,
    this.profile = const SectionState<PersonProfile>(),
    this.works = const SectionState<List<PersonWork>>(),
    this.voiceRoles = const SectionState<List<VoiceRole>>(),
    this.comments = const SectionState<List<PersonComment>>(),
  });

  final PersonSourceId id;
  final SectionState<PersonProfile> profile;
  final SectionState<List<PersonWork>> works;
  final SectionState<List<VoiceRole>> voiceRoles;
  final SectionState<List<PersonComment>> comments;

  PeopleDetailState copyWith({
    SectionState<PersonProfile>? profile,
    SectionState<List<PersonWork>>? works,
    SectionState<List<VoiceRole>>? voiceRoles,
    SectionState<List<PersonComment>>? comments,
  }) {
    return PeopleDetailState(
      id: id,
      profile: profile ?? this.profile,
      works: works ?? this.works,
      voiceRoles: voiceRoles ?? this.voiceRoles,
      comments: comments ?? this.comments,
    );
  }
}

final class PeopleController extends Notifier<PeopleDetailState> {
  PeopleController(this.id);

  final PersonSourceId id;
  final Map<PeopleSection, int> _generations = <PeopleSection, int>{};

  int _nextGeneration(PeopleSection section) =>
      _generations.update(section, (value) => value + 1, ifAbsent: () => 1);

  bool _isCurrent(PeopleSection section, int generation) =>
      _generations[section] == generation;

  @override
  PeopleDetailState build() => PeopleDetailState(id: id);

  Future<void> loadProfile({bool forceRefresh = false}) async {
    final generation = _nextGeneration(PeopleSection.profile);
    final previous = state.profile;
    state = state.copyWith(
      profile: previous.copyWith(
        status: SectionStatus.loading,
        clearError: true,
      ),
    );
    try {
      final value = await ref
          .read(peopleRepositoryProvider)
          .fetchProfile(id, forceRefresh: forceRefresh);
      if (!_isCurrent(PeopleSection.profile, generation)) {
        return;
      }
      state = state.copyWith(
        profile: SectionState<PersonProfile>(
          status: SectionStatus.fresh,
          value: value,
          page: 1,
          fetchedAt: DateTime.now(),
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(PeopleSection.profile, generation)) {
        return;
      }
      state = state.copyWith(
        profile: previous.copyWith(
          status: previous.hasContent
              ? SectionStatus.errorWithContent
              : SectionStatus.errorEmpty,
          error: error,
        ),
      );
    }
  }

  Future<void> loadWorks({bool forceRefresh = false}) async {
    await _loadList<PersonWork>(
      PeopleSection.works,
      forceRefresh: forceRefresh,
      fetch: (page) => ref
          .read(peopleRepositoryProvider)
          .fetchWorks(id, page, forceRefresh: forceRefresh),
      read: () => state.works,
      write: (next) => state = state.copyWith(works: next),
      merge: (oldItems, newItems) =>
          _merge(oldItems, newItems, (item) => item.animeId.value),
    );
  }

  Future<void> loadVoiceRoles({bool forceRefresh = false}) async {
    await _loadList<VoiceRole>(
      PeopleSection.voiceRoles,
      forceRefresh: forceRefresh,
      fetch: (page) => ref
          .read(peopleRepositoryProvider)
          .fetchVoiceRoles(id, page, forceRefresh: forceRefresh),
      read: () => state.voiceRoles,
      write: (next) => state = state.copyWith(voiceRoles: next),
      merge: (oldItems, newItems) =>
          _merge(oldItems, newItems, (item) => item.characterId.value),
    );
  }

  Future<void> loadComments({bool forceRefresh = false}) async {
    await _loadList<PersonComment>(
      PeopleSection.comments,
      forceRefresh: forceRefresh,
      fetch: (page) => ref
          .read(peopleRepositoryProvider)
          .fetchComments(id, page, forceRefresh: forceRefresh),
      read: () => state.comments,
      write: (next) => state = state.copyWith(comments: next),
      merge: (oldItems, newItems) =>
          _merge(oldItems, newItems, (item) => item.id),
    );
  }

  Future<void> loadMore(PeopleSection section) async {
    switch (section) {
      case PeopleSection.profile:
        return;
      case PeopleSection.works:
        return _loadWorksMore();
      case PeopleSection.voiceRoles:
        return _loadVoiceRolesMore();
      case PeopleSection.comments:
        return _loadCommentsMore();
    }
  }

  Future<void> retry(PeopleSection section) async {
    switch (section) {
      case PeopleSection.profile:
        return loadProfile(forceRefresh: true);
      case PeopleSection.works:
        return loadWorks(forceRefresh: true);
      case PeopleSection.voiceRoles:
        return loadVoiceRoles(forceRefresh: true);
      case PeopleSection.comments:
        return loadComments(forceRefresh: true);
    }
  }

  Future<void> _loadWorksMore() => _loadMoreList<PersonWork>(
    PeopleSection.works,
    state.works,
    (page) => ref.read(peopleRepositoryProvider).fetchWorks(id, page),
    (next) => state = state.copyWith(works: next),
    (oldItems, newItems) =>
        _merge(oldItems, newItems, (item) => item.animeId.value),
  );

  Future<void> _loadVoiceRolesMore() => _loadMoreList<VoiceRole>(
    PeopleSection.voiceRoles,
    state.voiceRoles,
    (page) => ref.read(peopleRepositoryProvider).fetchVoiceRoles(id, page),
    (next) => state = state.copyWith(voiceRoles: next),
    (oldItems, newItems) =>
        _merge(oldItems, newItems, (item) => item.characterId.value),
  );

  Future<void> _loadCommentsMore() => _loadMoreList<PersonComment>(
    PeopleSection.comments,
    state.comments,
    (page) => ref.read(peopleRepositoryProvider).fetchComments(id, page),
    (next) => state = state.copyWith(comments: next),
    (oldItems, newItems) => _merge(oldItems, newItems, (item) => item.id),
  );

  Future<void> _loadList<T>(
    PeopleSection section, {
    required bool forceRefresh,
    required Future<({List<T> items, bool hasMore})> Function(int page) fetch,
    required SectionState<List<T>> Function() read,
    required void Function(SectionState<List<T>> next) write,
    required List<T> Function(List<T> oldItems, List<T> newItems) merge,
  }) async {
    final current = read();
    if (current.status == SectionStatus.loading ||
        current.status == SectionStatus.loadingMore) {
      return;
    }
    final generation = _nextGeneration(section);
    write(
      current.copyWith(
        status: SectionStatus.loading,
        clearError: true,
        page: 0,
        clearValue: forceRefresh,
      ),
    );
    try {
      final result = await fetch(1);
      if (!_isCurrent(section, generation)) {
        return;
      }
      write(
        SectionState<List<T>>(
          status: result.items.isEmpty
              ? SectionStatus.empty
              : SectionStatus.fresh,
          value: result.items,
          page: 1,
          hasMore: result.hasMore,
          fetchedAt: DateTime.now(),
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(section, generation)) {
        return;
      }
      write(
        current.copyWith(
          status: current.hasContent
              ? SectionStatus.errorWithContent
              : SectionStatus.errorEmpty,
          error: error,
        ),
      );
    }
  }

  Future<void> _loadMoreList<T>(
    PeopleSection section,
    SectionState<List<T>> current,
    Future<({List<T> items, bool hasMore})> Function(int page) fetch,
    void Function(SectionState<List<T>> next) write,
    List<T> Function(List<T> oldItems, List<T> newItems) merge,
  ) async {
    if (!current.hasMore ||
        current.status == SectionStatus.loadingMore ||
        current.value == null) {
      return;
    }
    final generation = _nextGeneration(section);
    write(
      current.copyWith(status: SectionStatus.loadingMore, clearError: true),
    );
    try {
      final result = await fetch(current.page + 1);
      if (!_isCurrent(section, generation)) {
        return;
      }
      final merged = merge(current.value!, result.items);
      write(
        current.copyWith(
          status: merged.isEmpty ? SectionStatus.empty : SectionStatus.fresh,
          value: merged,
          page: current.page + 1,
          hasMore: result.hasMore,
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(section, generation)) {
        return;
      }
      write(
        current.copyWith(status: SectionStatus.errorWithContent, error: error),
      );
    }
  }

  static List<T> _merge<T>(
    List<T> oldItems,
    List<T> newItems,
    String Function(T item) keyOf,
  ) {
    final output = <String, T>{for (final item in oldItems) keyOf(item): item};
    for (final item in newItems) {
      output[keyOf(item)] = item;
    }
    return output.values.toList(growable: false);
  }
}

final peopleControllerProvider = NotifierProvider.autoDispose
    .family<PeopleController, PeopleDetailState, PersonSourceId>(
      PeopleController.new,
    );
