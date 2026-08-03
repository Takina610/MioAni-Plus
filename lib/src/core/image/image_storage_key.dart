import 'package:mio_ani/src/core/stable_hash.dart';

String createImageStorageKey(Uri uri) {
  return createStableHash128(uri.toString());
}
