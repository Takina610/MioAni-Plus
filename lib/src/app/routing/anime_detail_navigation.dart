import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_preview_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// Opens [anime]'s detail page, leaving what the list knows about it behind on
/// the way through.
///
/// The page is about to ask its source for the subject, which takes as long as
/// it takes; with the summary in the store it draws the cover, the title and
/// the score from what the reader was already looking at, and fills the rest in
/// as it arrives.
void openAnimeDetail(BuildContext context, WidgetRef ref, AnimeSummary anime) {
  ref.read(animePreviewStoreProvider).remember(anime);
  unawaited(AnimeDetailRouteData(id: anime.id.value).push<void>(context));
}
