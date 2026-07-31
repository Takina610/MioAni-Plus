import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:mio_ani/src/app/bootstrap/mio_ani_root.dart';

void bootstrapMioAniApp() {
  usePathUrlStrategy();
  runApp(const MioAniRoot());
}
