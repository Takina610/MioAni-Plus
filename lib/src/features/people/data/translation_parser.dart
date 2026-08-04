import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/features/people/domain/people_models.dart';

final class TranslationParser {
  const TranslationParser();

  List<TranslationBlock> parse(Object? payload) {
    if (payload is! List<Object?>) {
      throw const InvalidPayloadFailure();
    }
    final output = <TranslationBlock>[];
    for (final entry in payload) {
      if (entry is! Map<Object?, Object?>) {
        throw const InvalidPayloadFailure();
      }
      final source = entry['source'];
      final text = entry['text'];
      if (source is! String ||
          text is! String ||
          source.trim().isEmpty ||
          text.trim().isEmpty) {
        throw const InvalidPayloadFailure();
      }
      final language = entry['language'];
      if (language != null && language is! String) {
        throw const InvalidPayloadFailure();
      }
      output.add(
        TranslationBlock(
          source: source.trim(),
          text: text.trim(),
          language: language as String?,
        ),
      );
    }
    return output;
  }
}
