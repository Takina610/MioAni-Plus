import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/translation/application/translation_providers.dart';
import 'package:mio_ani/src/features/translation/data/translation_cache_store.dart';
import 'package:mio_ani/src/features/translation/data/translation_source.dart';

void main() {
  test('nothing is asked for until a reader asks', () async {
    final source = _FakeSource();
    final container = _container(source);

    final state = container.read(textTranslationProvider('ヤニねこ'));

    expect(state.phase, TranslationPhase.idle);
    expect(source.calls, isEmpty);
  });

  test('revealing fetches once and shows the answer', () async {
    final source = _FakeSource(translations: <String, String>{'ヤニねこ': '吸烟猫'});
    final container = _container(source);

    await container.read(textTranslationProvider('ヤニねこ').notifier).reveal();

    final state = container.read(textTranslationProvider('ヤニねこ'));
    expect(state.isShown, isTrue);
    expect(state.text, '吸烟猫');
    expect(source.calls, <String>['ja:ヤニねこ']);
  });

  test('hiding keeps the answer, and showing it again asks nobody', () async {
    // Comparing the two is the most natural thing to do with a translation
    // button, and asking the service again for the paragraph just read would
    // spend the reader's quota on a button press.
    final source = _FakeSource(translations: <String, String>{'ヤニねこ': '吸烟猫'});
    final container = _container(source);
    final notifier = container.read(textTranslationProvider('ヤニねこ').notifier);

    await notifier.reveal();
    notifier.toggle();
    expect(container.read(textTranslationProvider('ヤニねこ')).isShown, isFalse);

    await notifier.reveal();

    expect(container.read(textTranslationProvider('ヤニねこ')).text, '吸烟猫');
    expect(source.calls, hasLength(1));
  });

  test('a text translated before is answered from the cache', () async {
    final source = _FakeSource(translations: <String, String>{'ヤニねこ': '吸烟猫'});
    final cache = MemoryTranslationCacheStore();
    await cache.write('ヤニねこ', '吸烟猫');
    final container = _container(source, cache: cache);

    await container.read(textTranslationProvider('ヤニねこ').notifier).reveal();

    expect(container.read(textTranslationProvider('ヤニねこ')).text, '吸烟猫');
    expect(source.calls, isEmpty, reason: 'the answer was already on hand');
  });

  test('a fetch that worked is kept for the next session', () async {
    final source = _FakeSource(translations: <String, String>{'ヤニねこ': '吸烟猫'});
    final cache = MemoryTranslationCacheStore();
    final container = _container(source, cache: cache);

    await container.read(textTranslationProvider('ヤニねこ').notifier).reveal();

    expect(await cache.read('ヤニねこ'), '吸烟猫');
  });

  test('a refusal becomes a failure with its reason on it', () async {
    final source = _FakeSource(
      failures: <String, TranslationFailure>{
        'ヤニねこ': const TranslationFailure.rejectedKey(),
      },
    );
    final container = _container(source);

    await container.read(textTranslationProvider('ヤニねこ').notifier).reveal();

    final state = container.read(textTranslationProvider('ヤニねこ'));
    expect(state.hasFailed, isTrue);
    expect(state.failure?.message, contains('SecretId'));
    expect(state.text, isNull);
  });

  test('a failed text can be asked for again', () async {
    final source = _FakeSource(
      translations: <String, String>{'ヤニねこ': '吸烟猫'},
      failures: <String, TranslationFailure>{
        'ヤニねこ': const TranslationFailure(UpstreamFailure()),
      },
    );
    // The first attempt fails, the second is allowed through.
    final container = _container(source);
    final notifier = container.read(textTranslationProvider('ヤニねこ').notifier);

    await notifier.reveal();
    expect(container.read(textTranslationProvider('ヤニねこ')).hasFailed, isTrue);

    source.failures.clear();
    await notifier.reveal();

    expect(container.read(textTranslationProvider('ヤニねこ')).text, '吸烟猫');
  });

  test('the language comes from the text, not from the page', () async {
    final source = _FakeSource();
    final container = _container(source);

    await container
        .read(textTranslationProvider('Breaking Bear').notifier)
        .reveal();
    await container.read(textTranslationProvider('ヤニねこ').notifier).reveal();

    expect(source.calls, <String>['en:Breaking Bear', 'ja:ヤニねこ']);
  });

  test('two readers of the same text share one request', () async {
    // The button on a heading and the translation under the body watch the same
    // text, and a press on the button must not become two requests because the
    // widget was built twice.
    final source = _FakeSource(translations: <String, String>{'ヤニねこ': '吸烟猫'});
    final container = _container(source);
    final notifier = container.read(textTranslationProvider('ヤニねこ').notifier);

    await Future.wait(<Future<void>>[notifier.reveal(), notifier.reveal()]);

    expect(source.calls, hasLength(1));
  });

  test('a build with no credentials asks nobody', () async {
    final source = _FakeSource(translations: <String, String>{'ヤニねこ': '吸烟猫'});
    final container = ProviderContainer(
      overrides: [
        translationSourceProvider.overrideWithValue(null),
        translationConfiguredProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await container.read(textTranslationProvider('ヤニねこ').notifier).reveal();

    expect(source.calls, isEmpty);
    expect(
      container.read(textTranslationProvider('ヤニねこ')).phase,
      TranslationPhase.idle,
    );
  });
}

ProviderContainer _container(
  _FakeSource source, {
  MemoryTranslationCacheStore? cache,
}) {
  final container = ProviderContainer(
    overrides: [
      translationSourceProvider.overrideWithValue(source),
      translationConfiguredProvider.overrideWithValue(true),
      translationCacheStoreProvider.overrideWithValue(
        cache ?? MemoryTranslationCacheStore(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

final class _FakeSource implements TranslationSource {
  _FakeSource({
    this.translations = const <String, String>{},
    Map<String, TranslationFailure>? failures,
  }) : failures = failures ?? <String, TranslationFailure>{};

  final Map<String, String> translations;
  final Map<String, TranslationFailure> failures;
  final List<String> calls = <String>[];

  @override
  Future<String> translate(
    String text, {
    required TranslationLanguage from,
  }) async {
    calls.add('${from.code}:$text');
    final failure = failures[text];
    if (failure != null) throw failure;
    return translations[text] ?? '译文：$text';
  }
}
