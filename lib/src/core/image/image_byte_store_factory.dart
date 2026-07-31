import 'package:mio_ani/src/core/image/image_byte_store_factory_stub.dart'
    if (dart.library.io) 'package:mio_ani/src/core/image/image_byte_store_factory_native.dart'
    if (dart.library.js_interop) 'package:mio_ani/src/core/image/image_byte_store_factory_web.dart'
    as implementation;
import 'package:mio_ani/src/core/image/image_pipeline.dart';

ImageByteStore createPlatformImageByteStore() {
  return implementation.createPlatformImageByteStore();
}

Future<int> loadPlatformImageCacheCapacityBytes() {
  return implementation.loadPlatformImageCacheCapacityBytes();
}
