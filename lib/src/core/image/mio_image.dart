import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/core/network/request_coordinator.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

bool shouldUseWebDirectImageFallback({
  required bool isWeb,
  required Uri uri,
  required Object error,
  NetworkUriPolicy uriPolicy = const NetworkUriPolicy(),
}) {
  if (!isWeb || error is! OfflineFailure) return false;

  try {
    uriPolicy.validate(NetworkSource.bangumiImages, uri);
    return true;
  } on BrowserPolicyFailure {
    return false;
  }
}

class MioImage extends ConsumerWidget {
  const MioImage({
    required this.imageUrl,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
    this.borderRadius = MioRadii.md,
    super.key,
  });

  final Uri? imageUrl;
  final String semanticLabel;
  final BoxFit fit;
  final double borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = imageUrl;
    final child = uri == null
        ? _ImageFallback(
            icon: Icons.image_not_supported_outlined,
            label: '$semanticLabel：暂无图片',
          )
        : ref
              .watch(imageBytesProvider(uri))
              .when(
                data: (bytes) => _ImageBytes(
                  bytes: bytes,
                  fit: fit,
                  semanticLabel: semanticLabel,
                ),
                loading: () => _ImageFallback(
                  icon: Icons.downloading_outlined,
                  label: '$semanticLabel：图片加载中',
                  loading: true,
                ),
                error: (error, _) =>
                    shouldUseWebDirectImageFallback(
                      isWeb: kIsWeb,
                      uri: uri,
                      error: error,
                    )
                    ? _WebDirectImageFallback(
                        uri: uri,
                        fit: fit,
                        semanticLabel: semanticLabel,
                      )
                    : _ImageFallback(
                        icon: Icons.broken_image_outlined,
                        label: '$semanticLabel：图片加载失败',
                      ),
              );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(color: MioColors.surfaceHigh, child: child),
    );
  }
}

class _WebDirectImageFallback extends StatelessWidget {
  const _WebDirectImageFallback({
    required this.uri,
    required this.fit,
    required this.semanticLabel,
  });

  final Uri uri;
  final BoxFit fit;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      uri.toString(),
      fit: fit,
      gaplessPlayback: true,
      semanticLabel: semanticLabel,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => _ImageFallback(
        icon: Icons.broken_image_outlined,
        label: '$semanticLabel：图片加载失败',
      ),
    );
  }
}

class _ImageBytes extends StatelessWidget {
  const _ImageBytes({
    required this.bytes,
    required this.fit,
    required this.semanticLabel,
  });

  final Uint8List bytes;
  final BoxFit fit;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: fit,
      gaplessPlayback: true,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) => _ImageFallback(
        icon: Icons.broken_image_outlined,
        label: '$semanticLabel：图片解码失败',
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({
    required this.icon,
    required this.label,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final bool loading;

  static const double _loadingIndicatorDimension = 28;
  static const double _loadingIndicatorStrokeWidth = 2;
  static const double _fallbackIconSize = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      child: Center(
        child: loading
            ? const SizedBox.square(
                dimension: _loadingIndicatorDimension,
                child: CircularProgressIndicator(
                  strokeWidth: _loadingIndicatorStrokeWidth,
                ),
              )
            : Icon(
                icon,
                color: MioColors.textSecondary,
                size: _fallbackIconSize,
              ),
      ),
    );
  }
}
