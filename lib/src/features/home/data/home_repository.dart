import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

abstract interface class HomeRepository {
  /// Watches the catalog-derived home content (hero and season posters). The
  /// shell always receives a [HomeSnapshot], never a bare error: a failure
  /// arrives as a failed section.
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false});
}
