import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/features/translation/data/tencent_translation_source.dart';
import 'package:mio_ani/src/features/translation/data/translation_cache_store.dart';
import 'package:mio_ani/src/features/translation/data/translation_source.dart';
import 'package:mio_ani/src/features/translation/domain/translation_credentials.dart';

/// The credentials this build was given, which is nothing at all in a build
/// that was not given any.
final translationCredentialsProvider = Provider<TranslationCredentials>((ref) {
  return TranslationCredentials.fromEnvironment();
});

/// Whether this build can translate anything. A build with no key has no
/// translation, and the pages it draws do not offer one.
final translationConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(translationCredentialsProvider).isConfigured;
});

/// The service the app translates through, or null when there is no key to ask
/// it with.
final translationSourceProvider = Provider<TranslationSource?>((ref) {
  final credentials = ref.watch(translationCredentialsProvider);
  if (!credentials.isConfigured) return null;
  return TencentTranslationSource(
    dio: ref.watch(dioProvider),
    credentials: credentials,
    coordinator: ref.watch(requestCoordinatorProvider),
  );
});

/// Where a translation is kept once it has been fetched.
final translationCacheStoreProvider = Provider<TranslationCacheStore>((ref) {
  return DriftTranslationCacheStore(ref.watch(catalogDatabaseProvider));
});

/// What a piece of text on a page is doing: whether it is being translated, and
/// what came back.
enum TranslationPhase {
  /// Nothing is shown and nothing has been asked for. This is where every text
  /// starts: a page does not translate itself, and it does not ask a reader
  /// which parts of it they cannot read.
  idle,

  /// A request is out.
  running,

  /// The translation is shown under the text it came from.
  shown,

  /// The request came back with a reason instead of a translation.
  failed,
}

final class TextTranslationState {
  const TextTranslationState({
    this.phase = TranslationPhase.idle,
    this.text,
    this.failure,
  });

  const TextTranslationState.idle() : this();

  final TranslationPhase phase;

  /// The translation, once there is one.
  final String? text;

  /// Why there is none, when there is none.
  final TranslationFailure? failure;

  bool get isRunning => phase == TranslationPhase.running;
  bool get isShown => phase == TranslationPhase.shown && text != null;
  bool get hasFailed => phase == TranslationPhase.failed;

  /// What the button says, given what it is a button for.
  ///
  /// A running or shown button says what it is doing, and the same words do for
  /// a title, a synopsis and a row of tags. An idle one names its subject
  /// instead — `翻译标题` rather than `翻译` — because a page can carry three of
  /// these at once and a reader should not have to guess which does what.
  String labelFor(String subject) => switch (phase) {
    TranslationPhase.running => '翻译中',
    TranslationPhase.shown => '隐藏翻译',
    _ => subject,
  };
}

/// One text's translation, asked for by the reader.
///
/// The state is per text rather than per page: the title, the synopsis and the
/// tags are three independent asks, and reading one of them translated should
/// not translate the others. Nothing here runs until [reveal] is called, and
/// [hide] puts it back without throwing the answer away — a reader comparing
/// the two is doing the most natural thing with a translation button, and
/// asking the service again for the paragraph they just read would spend their
/// quota on a button press.
final class TextTranslationController extends Notifier<TextTranslationState> {
  TextTranslationController(this.source);

  final String source;

  @override
  TextTranslationState build() => const TextTranslationState.idle();

  Future<void> reveal() async {
    if (state.isRunning || state.isShown) return;
    final text = source.trim();
    if (text.isEmpty) return;

    final translation = ref.read(translationSourceProvider);
    if (translation == null) return;

    state = const TextTranslationState(phase: TranslationPhase.running);
    try {
      final cached = await ref.read(translationCacheStoreProvider).read(text);
      final translated =
          cached ?? await translation.translate(text, from: _language(text));
      if (cached == null) {
        // Written before it is shown, so the page a reader leaves and comes
        // back to does not ask for the same paragraph twice.
        await ref.read(translationCacheStoreProvider).write(text, translated);
      }
      if (!ref.mounted) return;
      state = TextTranslationState(
        phase: TranslationPhase.shown,
        text: translated,
      );
    } on TranslationFailure catch (failure) {
      if (!ref.mounted) return;
      state = TextTranslationState(
        phase: TranslationPhase.failed,
        failure: failure,
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = TextTranslationState(
        phase: TranslationPhase.failed,
        failure: TranslationFailure(failure),
      );
    }
  }

  void hide() {
    if (state.isRunning) return;
    state = const TextTranslationState.idle();
  }

  /// Toggles, which is what the button does: the same press reveals a
  /// translation and puts it away again. A press that arrives while a request
  /// is out is not a second request, it is the reader's finger on a button that
  /// has already done its job.
  void toggle() {
    if (state.isRunning) return;
    if (state.isShown || state.hasFailed) {
      hide();
      return;
    }
    reveal().ignore();
  }

  static TranslationLanguage _language(String text) {
    return TranslationLanguage.detect(text);
  }
}

/// The translation of one text, keyed by the text itself.
final textTranslationProvider = NotifierProvider.autoDispose
    .family<TextTranslationController, TextTranslationState, String>(
      TextTranslationController.new,
    );
