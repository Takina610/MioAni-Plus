import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// The language a piece of text on a page is written in, as far as the text
/// itself can say.
enum TextLanguage {
  /// Written in Chinese: what this app's reader reads.
  chinese,

  /// Written in Japanese.
  japanese,

  /// Written in English.
  english,

  /// Nothing here says. Empty, or too short to be anything.
  undetermined,
}

/// Letters that are Japanese and nothing else: the hiragana and katakana
/// letters, their iteration marks, and the halfwidth katakana.
///
/// The two marks that live in the same blocks are left out on purpose. `・`
/// (U+30FB) is a separator Chinese uses as readily as Japanese, and `ー`
/// (U+30FC) is a long-vowel mark that also appears in Chinese names. Counting
/// either as evidence of Japanese is what puts a translation button on a
/// Chinese page.
final RegExp _kana = RegExp(
  '[\u3041-\u3096\u309d-\u309f'
  '\u30a1-\u30fa\u30fd-\u30ff'
  '\uff66-\uff6f\uff71-\uff9d]',
);

/// Han characters, which both languages write with.
final RegExp _han = RegExp('[\u4e00-\u9fff]');

final RegExp _latin = RegExp('[A-Za-z]');

/// Fewest Latin letters that could be a language at all. Below it a value is
/// an acronym — a format, a season, an episode count — and translating `TV`
/// helps nobody.
const int _minimumLatinLetters = 3;

/// Fewest Latin letters in a run with no space in it before the run is read as
/// a word rather than a code.
///
/// `WEB`, `TVA` and `CUE` are three and four letters long and are tags on this
/// source, not text: a reader who cannot read English still knows what `WEB`
/// says, and a translation of it is the same word back. Five is where a run
/// stops looking like a code and starts looking like a name — `NARUTO` is a
/// title someone would want in Chinese, `AURA` is a studio.
const int _minimumLatinRun = 5;

/// Share of a text's Han-and-kana characters that has to be kana before the
/// text is read as Japanese.
///
/// A text written in Japanese is a mixture, and kana carries its grammar: no
/// prose gets far without it. A text written in Chinese is almost all Han, and
/// the kana in it is a name someone quoted — a studio, a song, a person. The
/// two do not overlap: over the sixty summer subjects this app shows, measured
/// against the source's own data, every Chinese text scored exactly zero and
/// every Japanese one scored above a quarter, with nothing in between. The line
/// is drawn inside that gap rather than at either edge of it.
const double _japaneseKanaShare = 0.15;

/// What language [text] is in, judged by the characters it is written with.
///
/// The judgement is deliberately one-sided. Saying `japanese` or `english` is a
/// claim that a reader of Chinese may not understand the text; saying `chinese`
/// is a claim that they will. Only the second is ever a guess, and it is the
/// safe direction to guess in — a page that says nothing is a page that offers
/// nothing.
TextLanguage detectTextLanguage(String? text) {
  final value = _normalized(text);
  if (value.isEmpty) return TextLanguage.undetermined;
  final kana = _kana.allMatches(value).length;
  final han = _han.allMatches(value).length;
  final latin = _latin.allMatches(value).length;

  // Latin script, and nothing else: a title or a synopsis the source published
  // in English. A single short run of letters is a label rather than a text
  // (see [_minimumLatinRun]), and a label is not a language.
  if (han == 0 && kana == 0) {
    if (latin < _minimumLatinLetters) return TextLanguage.undetermined;
    final readsAsWords = value.contains(' ') || latin >= _minimumLatinRun;
    return readsAsWords ? TextLanguage.english : TextLanguage.undetermined;
  }
  if (kana > 0 && kana / (kana + han) >= _japaneseKanaShare) {
    return TextLanguage.japanese;
  }
  // Han, and not enough kana to make it Japanese. Chinese is the right reading
  // of a text this app was built around, and the wrong one is caught upstream
  // by [workTitleReadsForeign] for the case that matters — a Japanese title
  // written in kanji alone, on a work the source files under Japan.
  if (han > 0) return TextLanguage.chinese;
  return TextLanguage.undetermined;
}

/// Whether [text] is written in something this app's reader may not read.
bool readsForeign(String? text) {
  return switch (detectTextLanguage(text)) {
    TextLanguage.japanese || TextLanguage.english => true,
    TextLanguage.chinese || TextLanguage.undetermined => false,
  };
}

/// Whether text [work] published is worth offering to translate.
///
/// A work the source files under China is a Chinese work: its page, its
/// synopsis and its tags are in Chinese, and a Chinese reader needs no help
/// with any of it. That is the whole reason [origin] is consulted here rather
/// than the characters alone — `万古至尊` and `銀魂` look alike to a script
/// test, and only one of them is worth translating.
bool workTextReadsForeign(String? text, {WorkOrigin? origin}) {
  if (origin == WorkOrigin.china) return false;
  return readsForeign(text);
}

/// Whether the title a page shows is worth offering to translate.
///
/// Unlike a synopsis, a title comes with its history attached, and three cases
/// can be told apart exactly:
///
/// * The page is showing a Chinese name the source published — the two names
///   differ — so there is nothing to translate, whatever the original was.
/// * The page is showing the work's own name, and the source files the work
///   under Japan. That name is Japanese even when it is written in nothing but
///   kanji, which is the case no amount of looking at the characters settles.
/// * The page is showing the work's own name and the source says nothing about
///   where it is from. Then the characters are all there is to go on, and the
///   answer is the same as for any other text.
bool workTitleReadsForeign({
  required String title,
  required String sourceTitle,
  WorkOrigin? origin,
}) {
  if (origin == WorkOrigin.china) return false;
  if (sourceTitle.isNotEmpty && title.isNotEmpty && title != sourceTitle) {
    return false;
  }
  if (origin == WorkOrigin.japan) return true;
  return readsForeign(title);
}

String _normalized(String? text) {
  return text == null ? '' : text.replaceAll(RegExp(r'\s+'), ' ').trim();
}
