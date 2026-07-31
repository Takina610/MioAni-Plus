import 'package:mio_ani/src/core/failures/app_failure.dart';

final class CatalogSnapshot<T> {
  const CatalogSnapshot({
    required this.value,
    required this.fetchedAt,
    required this.isStale,
    this.refreshFailure,
  });

  final T value;
  final DateTime fetchedAt;
  final bool isStale;
  final AppFailure? refreshFailure;
}
