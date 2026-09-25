import 'package:mio_ani/src/core/failures/app_failure.dart';

/// The language a text on a page is written in.
///
/// Only the two the app meets are named. A work is published in Japanese, or —
/// when its source has no Japanese name either — in English; there is no third
/// case in the catalogue, and a text in Chinese is never translated at all.
enum TranslationLanguage {
  japanese('ja'),
  english('en');

  const TranslationLanguage(this.code);

  /// The service's own name for the language.
  final String code;

  /// Which of the two [text] is written in. Kana mean Japanese; anything else
  /// that reached this point is Latin and so English.
  static TranslationLanguage detect(String text) {
    return _kana.hasMatch(text)
        ? TranslationLanguage.japanese
        : TranslationLanguage.english;
  }

  static final RegExp _kana = RegExp(r'[\u3040-\u30ff]');
}

/// Turns text into Chinese.
abstract interface class TranslationSource {
  /// [text] written in [from], in Chinese.
  ///
  /// Throws a [TranslationFailure] when the service could not be asked or would
  /// not answer.
  Future<String> translate(String text, {required TranslationLanguage from});
}

/// A translation that could not be fetched.
///
/// [detail] is the reason to show when the app knows something more specific
/// than [failure] does — a rejected key is not "the source refused this
/// request", it is a build that was given the wrong credentials.
final class TranslationFailure implements Exception {
  const TranslationFailure(this.failure, {this.detail});

  const TranslationFailure.rejectedKey()
    : failure = const ForbiddenFailure(),
      detail = '翻译服务拒绝了当前密钥，请检查构建时传入的 SecretId 与 SecretKey';

  final AppFailure failure;
  final String? detail;

  /// What the page shows.
  String get message => detail ?? failure.userMessage;

  @override
  String toString() => 'TranslationFailure(${failure.kind.name})';
}
