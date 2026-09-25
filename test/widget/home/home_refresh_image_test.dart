import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_source_id.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';
import 'package:mio_ani/src/features/home/application/home_providers.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';
import 'package:mio_ani/src/features/home/presentation/home_page.dart';

import '../../support/fake_home_repository.dart';
import '../../support/test_viewport.dart';

void main() {
  testWidgets('pulling the page down asks for its posters again', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final poster = Uri.parse('https://lain.bgm.tv/pic/cover/l/aa/bb/1.jpg');
    final pipeline = _FailingImagePipeline();
    final repository = FakeHomeRepository(
      watchFactory: () => Stream.value(
        testHomeSnapshot(
          catalog: HomeSection<HomeCatalogContent>.ready(
            value: HomeCatalogContent(
              hero: <AnimeSummary>[],
              trending: <AnimeSummary>[_anime(poster)],
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeRepositoryProvider.overrideWithValue(repository),
          imagePipelineProvider.overrideWithValue(pipeline),
        ],
        retry: disableProviderRetry,
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();
    // A frame for the download to fail and another for the tile to show it.
    await tester.pump();

    // The cover failed to download, and a failed image stays failed for as long
    // as its tile lives: nothing else on the page would ask for it again.
    expect(pipeline.calls, 1);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    // Pulling the page down is how a reader heals that: the poster is asked for
    // again rather than staying broken until it happens to be rebuilt.
    expect(pipeline.calls, 2);
    expect(tester.takeException(), isNull);
  });
}

AnimeSummary _anime(Uri image) {
  return AnimeSummary(
    id: AnimeSourceId.fromBangumiId(1),
    title: '海报',
    sourceTitle: '',
    imageUrl: image,
  );
}

/// Fails every download, the way a cover that timed out in the request queue
/// behaves: the bytes are never there and the pipeline reports a failure.
final class _FailingImagePipeline implements ImagePipeline {
  int calls = 0;

  @override
  Future<Uint8List> load(Uri uri) async {
    calls += 1;
    throw const OfflineFailure();
  }
}
