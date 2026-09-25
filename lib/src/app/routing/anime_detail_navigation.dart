import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/app/routing/app_routes.dart';
import 'package:mio_ani/src/core/image/mio_cover_flight.dart';
import 'package:mio_ani/src/features/anime_detail/application/anime_preview_store.dart';
import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// Opens [anime]'s detail page, leaving what the list knows about it behind on
/// the way through.
///
/// The page is about to ask its source for the subject, which takes as long as
/// it takes; with the summary in the store it draws the cover, the title and
/// the score from what the reader was already looking at, and fills the rest in
/// as it arrives.
///
/// [cover] is the picture the reader tapped, when the thing they tapped had
/// one: the page draws its poster as the far end of that flight, so what lands
/// on it is the work the reader was looking at. A tap from a row without a
/// picture — a line of the schedule, an entry in the library — passes nothing,
/// and the last cover a reader tapped is left standing, so the work still flies
/// from the list that is showing one.
void openAnimeDetail(
  BuildContext context,
  WidgetRef ref,
  AnimeSummary anime, {
  AnimeCoverFlight? cover,
}) {
  ref.read(animePreviewStoreProvider).remember(anime);
  if (cover != null) {
    ref.read(animeCoverFlightStoreProvider).begin(cover);
  }
  unawaited(AnimeDetailRouteData(id: anime.id.value).push<void>(context));
}
