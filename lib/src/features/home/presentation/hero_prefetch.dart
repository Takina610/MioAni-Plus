import 'package:mio_ani/src/features/catalog/domain/anime_summary.dart';

/// Bounded hero image prefetch: only the current and next carousel slides are
/// warmed, and a per-widget set prevents duplicate/backlogged requests. Old
/// hero requests never survive a carousel index jump.
final class HeroImagePrefetcher {
  final Set<Uri> _requested = <Uri>{};

  /// Ensures [items][current] and the next slide are requested through
  /// [request]. Any earlier slide (e.g. after a fast swipe backwards) is not
  /// re-requested.
  void prefetch({
    required void Function(Uri uri) request,
    required List<AnimeSummary> items,
    required int current,
  }) {
    if (items.isEmpty) return;
    final next = (current + 1) % items.length;
    final indexes = <int>[current, next];
    for (final index in indexes) {
      final uri = items[index].imageUrl;
      if (uri == null || !_requested.add(uri)) continue;
      request(uri);
    }
  }

  void clear() {
    _requested.clear();
  }
}
