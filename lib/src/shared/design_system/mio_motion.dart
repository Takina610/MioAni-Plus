import 'package:flutter/widgets.dart';

abstract final class MioMotion {
  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}
