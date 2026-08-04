import 'package:mio_ani/src/features/imports/data/import_source.dart';
import 'package:mio_ani/src/features/imports/domain/import_models.dart';
import 'package:mio_ani/src/features/imports/domain/import_staging.dart';

final class ImportService {
  const ImportService(this.sources);

  final Map<ImportSource, PublicCollectionSource> sources;

  Future<ImportSnapshot> fetchSnapshot({
    required ImportSource source,
    required String input,
    ImportCancellationToken? cancellation,
    bool forceNewGeneration = false,
    ImportProgressListener? onProgress,
  }) async {
    final adapter = sources[source];
    if (adapter == null) {
      throw const ImportIntegrityException('未配置该来源的公开收藏适配器。');
    }
    final token = cancellation ?? ImportCancellationToken();
    onProgress?.call(
      const ImportProgress(
        stage: ImportStage.resolving,
        pagesFetched: 0,
        itemsParsed: 0,
        message: '正在解析公开账号',
      ),
    );
    token.throwIfCancelled();
    final profile = await adapter.resolveAccount(
      input,
      forceNewGeneration: forceNewGeneration,
    );
    token.throwIfCancelled();
    final session = ImportStagingSession(
      sessionId:
          'session:${DateTime.now().toUtc().microsecondsSinceEpoch}:${profile.key.value}',
      profile: profile,
      onProgress: onProgress,
    );
    return collectPages(
      session: session,
      cancellation: token,
      fetchPage: (page) => adapter.fetchCollectionPage(
        profile,
        page,
        forceNewGeneration: forceNewGeneration,
      ),
    );
  }
}
