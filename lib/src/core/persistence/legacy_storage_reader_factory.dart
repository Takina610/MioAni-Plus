import 'package:mio_ani/src/core/persistence/legacy_migration.dart';
import 'package:mio_ani/src/core/persistence/legacy_storage_reader_stub.dart'
    if (dart.library.io) 'package:mio_ani/src/core/persistence/legacy_storage_reader_native.dart'
    if (dart.library.js_interop) 'package:mio_ani/src/core/persistence/legacy_storage_reader_web.dart'
    as implementation;

LegacyStorageReader createPlatformLegacyStorageReader() {
  return implementation.createPlatformLegacyStorageReader();
}
