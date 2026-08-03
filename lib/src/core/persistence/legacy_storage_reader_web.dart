import 'package:mio_ani/src/core/persistence/legacy_migration.dart';
import 'package:web/web.dart' as web;

const String vueLibraryStorageKey = 'mioani-library-v1';
const String vueProfileStorageKey = 'mioani-profile-v1';

LegacyStorageReader createPlatformLegacyStorageReader() {
  return const WebLegacyStorageReader();
}

final class WebLegacyStorageReader implements LegacyStorageReader {
  const WebLegacyStorageReader();

  @override
  Future<LegacyStorageSnapshot> read() async {
    try {
      final storage = web.window.localStorage;
      final library = storage.getItem(vueLibraryStorageKey);
      final profile = storage.getItem(vueProfileStorageKey);
      return LegacyStorageSnapshot(
        libraryJson: _normalize(library),
        profileJson: _normalize(profile),
      );
    } catch (_) {
      // Unavailable or restricted localStorage is treated as absence so the
      // bootstrap can report a diagnostic without claiming a successful wipe.
      return const LegacyStorageSnapshot();
    }
  }

  static String? _normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : value;
  }
}
