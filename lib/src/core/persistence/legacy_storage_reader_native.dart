import 'package:mio_ani/src/core/persistence/legacy_migration.dart';

LegacyStorageReader createPlatformLegacyStorageReader() {
  // Vue localStorage keys exist only in the browser. Native builds never touch
  // browser APIs and report absence so migration is a no-op.
  return const EmptyLegacyStorageReader();
}
