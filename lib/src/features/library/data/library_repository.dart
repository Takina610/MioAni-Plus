import 'dart:async';

import 'package:mio_ani/src/features/library/domain/library_models.dart';
import 'package:mio_ani/src/features/library/domain/library_query.dart';

final class LibraryRecord {
  const LibraryRecord({required this.identity, required this.entry});
  final AnimeIdentity identity;
  final LibraryEntry entry;
  String get title => identity.canonicalTitle;
}

class LibraryRepositoryException implements Exception {
  const LibraryRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

final class LibraryRevisionConflict extends LibraryRepositoryException {
  const LibraryRevisionConflict({required this.expected, required this.actual})
    : super('本地数据已被其他窗口修改，请重新预览后再提交。');
  final int expected;
  final int actual;
}

final class LibraryReviewRequired extends LibraryRepositoryException {
  const LibraryReviewRequired(this.candidateId) : super('发现相似作品候选，请先完成身份评审。');
  final String candidateId;
}

final class LibraryStateConflictException extends LibraryRepositoryException {
  const LibraryStateConflictException() : super('状态存在冲突，请明确选择要继承的状态后再提交。');
}

abstract interface class LibraryRepository {
  Stream<List<LibraryRecord>> watchLibrary({
    LibraryQuery query = const LibraryQuery(),
  });
  Future<List<LibraryRecord>> readLibrary({
    LibraryQuery query = const LibraryQuery(),
  });
  Future<LibraryRecord> addLocal(
    SourceObservation observation, {
    LibraryWatchStatus status = LibraryWatchStatus.planned,
    int watched = 0,
    int? expectedRevision,
  });
  Future<void> remove(AnimeIdentityId identityId, {int? expectedRevision});
  Future<LibraryEntry> setStatus(
    AnimeIdentityId identityId,
    LibraryWatchStatus status, {
    int? expectedRevision,
  });
  Future<LibraryEntry> setProgress(
    AnimeIdentityId identityId,
    int watched, {
    int? expectedRevision,
  });
  IdentityPlan planObservation(SourceObservation observation);
  Future<void> confirmCandidate(String candidateId, {int? expectedRevision});
  Future<void> keepSeparate(String candidateId, {int? expectedRevision});
  Future<void> ignoreCandidate(String candidateId, {int? expectedRevision});
  MergePreview previewMerge(
    AnimeIdentityId leftId,
    AnimeIdentityId rightId, {
    int? expectedRevision,
  });
  Future<AnimeIdentityId> commitMerge(
    AnimeIdentityId leftId,
    AnimeIdentityId rightId, {
    int? expectedRevision,
    LibraryWatchStatus? resolvedStatus,
    int? resolvedWatched,
  });
  SplitPreview previewSplit(
    AnimeIdentityId identityId,
    AnimeIdentityId inheritStateTo, {
    int? expectedRevision,
  });
  Future<List<AnimeIdentityId>> commitSplit(
    AnimeIdentityId identityId,
    AnimeIdentityId inheritStateTo, {
    int? expectedRevision,
  });
  Future<LibraryOperation?> undo(String operationId);
  Future<void> clearPublicCache();
  Future<void> clearFlutterUserData();
  Future<void> deleteVueLegacyKeys();
  int get revision;
  List<IdentityCandidate> get pendingCandidates;
  List<IdentityDecision> get decisions;
}
