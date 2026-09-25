import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool disableAnimations = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(body: Center(child: child)),
        ),
      ),
    );
  }

  /// Frames waiting on the shimmer: one shared ticker while a block is on
  /// screen, none once it is gone.
  int tickers(WidgetTester tester) => tester.binding.transientCallbackCount;

  testWidgets('a block with no width of its own takes the width offered', (
    tester,
  ) async {
    await pump(
      tester,
      const SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MioPlaceholderLines(lines: 3, lineHeight: 14),
            MioPlaceholder(height: 40),
          ],
        ),
      ),
    );
    await tester.pump();

    // A line standing in for a paragraph is as wide as the paragraph would
    // have been, and the last one stops short — the shape that says the text
    // has ended rather than been cut off. A block that measured itself at zero
    // would leave the page's skeleton, which is the app's whole answer to
    // loading, invisible; that is what every `MioPlaceholderLines` in the app
    // was drawing.
    final widths = <double>[
      for (final element in find.byType(MioPlaceholder).evaluate())
        (element.renderObject! as RenderBox).size.width,
    ];
    expect(widths, <double>[300, 300, 180, 300]);
  });

  testWidgets('a waiting block shimmers, and stops when it is gone', (
    tester,
  ) async {
    await pump(
      tester,
      const MioSkeletonScope(child: MioPlaceholder(width: 120, height: 80)),
    );

    // The block is on screen and waiting, so the sweep is running.
    expect(tickers(tester), 1);
    await tester.pump(const Duration(milliseconds: 700));
    expect(tickers(tester), 1);

    // The content has landed: the block is gone with the wait it stood for, and
    // nothing on the page is painting any more.
    await pump(tester, const MioSkeletonScope(child: SizedBox.shrink()));
    expect(tickers(tester), 0);
  });

  testWidgets('every block on a screen shares the one sweep', (tester) async {
    await pump(
      tester,
      const MioSkeletonScope(
        child: Column(
          children: <Widget>[
            MioPlaceholder(width: 120, height: 40),
            MioPlaceholder(width: 120, height: 40),
            MioPlaceholderLines(lines: 3),
          ],
        ),
      ),
    );

    // Three blocks and their lines, one ticker: a grid of waiting posters is
    // dozens of blocks, and a ticker each is work the page cannot spare.
    expect(tickers(tester), 1);
  });

  testWidgets('blocks with no scope above them are drawn still', (
    tester,
  ) async {
    await pump(tester, const MioPlaceholder(width: 120, height: 80));

    // A screen built on its own — a widget test, a preview — does not start an
    // endless animation behind the caller's back.
    expect(tickers(tester), 0);
    expect(find.byType(MioPlaceholder), findsOneWidget);
  });

  testWidgets('a block on a covered page stops painting', (tester) async {
    await pump(
      tester,
      const MioSkeletonScope(child: MioPlaceholder(width: 120, height: 80)),
    );
    expect(tickers(tester), 1);

    // Another route has come forward: the page behind it is muted, and its
    // blocks are not waiting for anyone any more.
    await pump(
      tester,
      const MioSkeletonScope(
        child: TickerMode(
          enabled: false,
          child: MioPlaceholder(width: 120, height: 80),
        ),
      ),
    );

    expect(tickers(tester), 0);
    expect(find.byType(MioPlaceholder), findsOneWidget);
  });

  testWidgets('reduced motion keeps the blocks and drops the sweep', (
    tester,
  ) async {
    await pump(
      tester,
      const MioSkeletonScope(child: MioPlaceholder(width: 120, height: 80)),
      disableAnimations: true,
    );

    expect(tickers(tester), 0);
    expect(find.byType(MioPlaceholder), findsOneWidget);
  });

  testWidgets('the wave is always on the block, and never jumps', (
    tester,
  ) async {
    // A still block: what the skeleton looks like with no shimmer at all. It is
    // the floor the wave has to stay above.
    await pump(
      tester,
      const RepaintBoundary(
        key: _blockBoundary,
        child: MioPlaceholder(width: 200, height: 60, radius: 0),
      ),
    );
    final base = await _peakBrightness(tester);

    // The same block with the shimmer, sampled across a whole cycle (1400ms):
    // twelve moments of it.
    await pump(
      tester,
      const MioSkeletonScope(
        child: RepaintBoundary(
          key: _blockBoundary,
          child: MioPlaceholder(width: 200, height: 60, radius: 0),
        ),
      ),
    );
    final samples = <double>[];
    final pictures = <List<int>>[];
    for (var index = 0; index < 12; index += 1) {
      samples.add(await _peakBrightness(tester));
      pictures.add(await _pixels(tester));
      await tester.pump(const Duration(milliseconds: 116));
    }

    // A crest is on the block at every moment: sweeping a band that leaves the
    // block altogether would show up here as a sample at the bare floor, which
    // is the light stopping and starting again.
    final amplitude = samples.reduce(math.max) - base;
    expect(amplitude, greaterThan(0.02));
    for (final sample in samples) {
      expect(sample, greaterThan(base + amplitude * 0.2));
    }

    // And the block is never still: every moment differs from the one before,
    // including the one that crosses the cycle's join.
    for (var index = 1; index < pictures.length; index += 1) {
      expect(pictures[index], isNot(pictures[index - 1]));
    }
  });

  testWidgets('the wave moves across the block', (tester) async {
    await pump(
      tester,
      const MioSkeletonScope(
        child: RepaintBoundary(
          key: _blockBoundary,
          child: MioPlaceholder(width: 200, height: 60, radius: 0),
        ),
      ),
    );

    // The highlight is painted from the shared animation, so two moments of it
    // are two different pictures of the same block.
    final first = await _pixels(tester);
    await tester.pump(const Duration(milliseconds: 350));
    final second = await _pixels(tester);

    expect(first, isNot(second));
  });
}

const Key _blockBoundary = Key('skeleton-block');

/// Brightest pixel of the rendered block, as a 0–1 fraction of full intensity.
Future<double> _peakBrightness(WidgetTester tester) async {
  final bytes = await _pixels(tester);
  var peak = 0;
  for (var index = 0; index + 3 < bytes.length; index += 4) {
    final value = math.max(
      bytes[index],
      math.max(bytes[index + 1], bytes[index + 2]),
    );
    if (value > peak) peak = value;
  }
  return peak / 255;
}

/// The rendered block, as bytes, so a test can say the sweep moved.
Future<List<int>> _pixels(WidgetTester tester) async {
  late List<int> bytes;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_blockBoundary),
    );
    final image = await boundary.toImage();
    final data = await image.toByteData();
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });
  return bytes;
}
