import 'package:flutter/widgets.dart';

abstract final class MioMotion {
  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }

  /// Whether the reader has asked the platform not to animate anything.
  ///
  /// [resolve] already answers this for a duration — an animation asked for no
  /// time is over before it starts — and a widget that would rather not start
  /// one at all asks here instead.
  static bool isDisabled(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }
}
