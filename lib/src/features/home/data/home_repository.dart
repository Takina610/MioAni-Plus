import 'package:mio_ani/src/features/home/domain/home_explore.dart';
import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

abstract interface class HomeRepository {
  /// Watches the catalog-derived home content (hero and season posters). The
  /// shell always receives a [HomeSnapshot], never a bare error: a failure
  /// arrives as a failed section.
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false});

  /// The explore feed as far as it is already known.
  ///
  /// A warm cache answers without a request; a refresh re-reads the head of the
  /// ranking and keeps the pages the user had already scrolled to. When the
  /// refresh fails, a still-usable cached feed stands in.
  Future<HomeExplorePage> readExploreFeed({bool forceRefresh = false});

  /// The explore page at [page], merged onto the feed already loaded.
  ///
  /// Unlike [readExploreFeed] a failure here travels to the caller: the feed on
  /// screen is unaffected, so the section can offer a retry without losing what
  /// it already shows.
  Future<HomeExplorePage> loadExplorePage(int page);
}
