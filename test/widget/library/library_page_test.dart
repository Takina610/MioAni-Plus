import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';
import 'package:mio_ani/src/features/library/application/library_providers.dart';
import 'package:mio_ani/src/features/library/data/library_repository.dart';
import 'package:mio_ani/src/features/library/domain/library_models.dart';
import 'package:mio_ani/src/features/library/domain/library_query.dart';
import 'package:mio_ani/src/features/library/presentation/library_page.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';

import '../../support/test_viewport.dart';

void main() {
  testWidgets('the shelf stands up as rows of records while it is read', (
    tester,
  ) async {
    await configureTestViewport(tester, size: const Size(390, 844));
    final shelf = Completer<List<LibraryRecord>>();
    addTearDown(() {
      if (!shelf.isCompleted) shelf.complete(const <LibraryRecord>[]);
    });

    await _pumpLibrary(tester, shelf);

    // Nothing spins while the shelf is being read: the rows a record takes are
    // already standing, in the card and the controls the real ones will have.
    expect(find.byType(MioPlaceholder), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('我的追番库'), findsOneWidget);
    expect(tester.takeException(), isNull);

    shelf.complete(const <LibraryRecord>[]);
    await tester.pumpAndSettle();

    // An empty shelf says so; the blocks are gone with the wait they stood for.
    expect(find.byType(MioPlaceholder), findsNothing);
  });
}

Future<void> _pumpLibrary(
  WidgetTester tester,
  Completer<List<LibraryRecord>> shelf,
) {
  const query = LibraryQuery();
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        libraryRepositoryProvider.overrideWithValue(_EmptyLibraryRepository()),
        libraryStreamProvider(query).overrideWith(
          (ref) => Stream<List<LibraryRecord>>.fromFuture(shelf.future),
        ),
      ],
      retry: disableProviderRetry,
      child: const MaterialApp(home: LibraryPage()),
    ),
  );
}

/// Only the two things the page reads before a record exists: the shelf badge
/// and the stream, which the test supplies itself.
final class _EmptyLibraryRepository implements LibraryRepository {
  @override
  List<IdentityCandidate> get pendingCandidates => const <IdentityCandidate>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
