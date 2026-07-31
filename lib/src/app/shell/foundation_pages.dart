import 'package:flutter/material.dart';
import 'package:mio_ani/src/app/shell/mio_destination.dart';
import 'package:mio_ani/src/core/config/app_config.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

class FoundationDestinationPage extends StatelessWidget {
  const FoundationDestinationPage({required this.destination, super.key});

  final MioDestination destination;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: MioSizes.contentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(MioSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppConfig.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: MioSpacing.md),
                  Text(
                    destination.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: MioSpacing.xs),
                  Text(
                    '基础外壳已就绪，内容将在后续纵向切片接入。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FoundationDetailPage extends StatelessWidget {
  const FoundationDetailPage({
    required this.title,
    required this.sourceId,
    super.key,
  });

  final String title;
  final String sourceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(MioSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(sourceId),
                const SizedBox(height: MioSpacing.md),
                const Text('此路由契约已就绪，业务内容将在后续切片接入。'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoundationNotFoundPage extends StatelessWidget {
  const FoundationNotFoundPage({required this.location, super.key});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: MioStateView.notFound(message: '无法识别路径：$location'));
  }
}
