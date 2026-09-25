import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// What the lists already know about the anime a reader opened.
///
/// A tap carries an id and nothing else, so before this store a reader who
/// tapped a poster landed on a detail page with nothing to draw until the
/// subject request answered — one call to a source that answers in a second or
/// more, spent on a screen that was empty for all of it. The list the tap came
/// from was holding the cover, the title and the score already, so a tap leaves
/// that summary here and the detail page draws its head with it.
///
/// Only what the reader actually opened is kept, which keeps this small, and it
/// is bounded anyway: a long browsing session is a lot of taps.
final class AnimePreviewStore {
  AnimePreviewStore({this.maximumEntries = 64});

  final int maximumEntries;

  /// Insertion order is recency: the newest tap is last.
  final LinkedHashMap<String, AnimeSummary> _entries =
      LinkedHashMap<String, AnimeSummary>();

  int get length => _entries.length;

  /// Remembers [anime] as the last thing known about it.
  void remember(AnimeSummary anime) {
    _entries.remove(anime.id.value);
    _entries[anime.id.value] = anime;
    while (_entries.length > maximumEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// What a list last showed for [id], or null when nothing has.
  AnimeSummary? lookup(String id) => _entries[id];

  void forget(String id) => _entries.remove(id);

  void clear() => _entries.clear();
}

final animePreviewStoreProvider = Provider<AnimePreviewStore>((ref) {
  return AnimePreviewStore();
});
