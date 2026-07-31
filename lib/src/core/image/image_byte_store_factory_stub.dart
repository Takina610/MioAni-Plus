import 'package:mio_ani/src/core/image/image_pipeline.dart';

ImageByteStore createPlatformImageByteStore() {
  return MemoryImageByteStore();
}

Future<int> loadPlatformImageCacheCapacityBytes() async {
  return const ImageCacheCapacityPolicy().capacityFor(
    platform: ImageCachePlatform.unsupported,
  );
}
