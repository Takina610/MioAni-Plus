import 'dart:io';

import 'package:mio_ani/src/core/image/image_byte_store_native.dart';
import 'package:mio_ani/src/core/image/image_pipeline.dart';

ImageByteStore createPlatformImageByteStore() {
  return NativeFileImageByteStore();
}

Future<int> loadPlatformImageCacheCapacityBytes() async {
  const policy = ImageCacheCapacityPolicy();
  if (Platform.isAndroid) {
    return policy.capacityFor(platform: ImageCachePlatform.android);
  }
  if (Platform.isWindows) {
    return policy.capacityFor(platform: ImageCachePlatform.windows);
  }
  return policy.capacityFor(platform: ImageCachePlatform.unsupported);
}
