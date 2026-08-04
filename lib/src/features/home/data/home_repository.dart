import 'package:mio_ani/src/features/home/domain/home_snapshot.dart';

abstract interface class HomeRepository {
  /// Watches all home partitions. Catalog sections (hero/recommended/trending)
  /// and schedule sections (recent/preview) fail and refresh independently;
  /// the shell always receives a [HomeSnapshot], never a bare error.
  Stream<HomeSnapshot> watchHome({bool forceRefresh = false});
}
