import 'package:flutter/material.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';

class FoundationNotFoundPage extends StatelessWidget {
  const FoundationNotFoundPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MioStateView.notFound(message: '无法识别路径：$location'));
  }
}
