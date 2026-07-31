import 'package:mio_ani/src/core/image/image_byte_store_web.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';

ImageByteStore createPlatformImageByteStore() {
  return WebCacheStorageImageByteStore();
}

Future<int> loadPlatformImageCacheCapacityBytes() {
  return loadWebImageCacheCapacityBytes();
}
