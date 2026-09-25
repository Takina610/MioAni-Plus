import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The app never narrates its own caching.
///
/// A reader who taps a poster is about to see a page, and how the app got the
/// page — off the network this second or off the disk from a while ago, being
/// refreshed or done — is not part of what they asked for. A line saying
/// "showing cached content, updating now" tells them to doubt the page they are
/// looking at, and there is nothing they can do about it either way: the page
/// either has the work or it does not.
///
/// This is a source-level check rather than a widget test because the rule is
/// about the words the app is allowed to say anywhere, including screens and
/// states a widget test would have to be built specially to reach. It is the
/// one shape of check that cannot be forgotten on the next page.
void main() {
  test('no screen tells the reader about the cache', () {
    final phrases = <String>[
      '正在引用缓存',
      '已缓存的详情',
      '正在更新缓存',
      '离线缓存',
      '重试更新',
      '内容更新时间',
      '正在联网更新',
      '正在同步',
      '缓存已过期',
    ];

    final offenders = <String>[];
    for (final file in _dartSources()) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index += 1) {
        for (final phrase in phrases) {
          if (lines[index].contains(phrase)) {
            offenders.add('${_relative(file.path)}:${index + 1}: $phrase');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'the UI must not narrate its caching; a page either has the work or '
          'it does not.\nFound:\n${offenders.join('\n')}',
    );
  });

  test('the check is looking at the app', () {
    // A source scan is only worth anything if it actually found the sources:
    // a wrong working directory would make every assertion above pass by
    // looking at nothing.
    final sources = _dartSources().toList(growable: false);
    expect(sources.length, greaterThan(50));
    expect(sources.any((file) => file.path.endsWith('home_page.dart')), isTrue);
  });
}

Iterable<File> _dartSources() {
  return Directory('lib/src')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      // Generated code is not written by anyone and not read by anyone.
      .where((file) => !file.path.endsWith('.g.dart'));
}

String _relative(String path) => path.replaceAll(r'\', '/');
