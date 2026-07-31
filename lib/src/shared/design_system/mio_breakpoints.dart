enum MioWindowClass { compact, medium, expanded }

abstract final class MioBreakpoints {
  static const double medium = 600;
  static const double expanded = 1024;

  static MioWindowClass windowClassFor(double width) {
    if (!width.isFinite || width < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'must be finite and non-negative',
      );
    }
    if (width < medium) {
      return MioWindowClass.compact;
    }
    if (width < expanded) {
      return MioWindowClass.medium;
    }
    return MioWindowClass.expanded;
  }
}
