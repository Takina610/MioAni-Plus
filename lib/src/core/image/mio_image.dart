import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/core/network/network_uri_policy.dart';
import 'package:mio_ani/src/features/catalog/application/catalog_providers.dart';
import 'package:mio_ani/src/shared/design_system/mio_motion.dart';
import 'package:mio_ani/src/shared/design_system/mio_placeholder.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

bool shouldUseWebDirectImageFallback({
  required bool isWeb,
  required Uri uri,
  required Object error,
  NetworkUriPolicy uriPolicy = const NetworkUriPolicy(),
}) {
  if (!isWeb || error is! OfflineFailure) return false;

  try {
    uriPolicy.resolveImageSource(uri);
    return true;
  } on BrowserPolicyFailure {
    return false;
  }
}

/// A cover, drawn as soon as its bytes are on hand.
///
/// Three things decide how it feels. A poster this run has already drawn is
/// read straight out of [imageMemoryCacheProvider] and painted in the same
/// frame, so scrolling back over covers costs nothing. One being read for the
/// first time is drawn as the skeleton block the rest of the app loads with,
/// and the poster lands in it — a grid of spinners over a wall of posters is
/// noise, and a poster-sized block of the tile's own colour is a hole in it.
/// And the bytes are decoded at the size the widget is actually given, so a
/// poster tile decodes a few hundred pixels wide instead of a full-resolution
/// cover.
class MioImage extends ConsumerWidget {
  const MioImage({
    required this.imageUrl,
    required this.semanticLabel,
    this.previewUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius = MioRadii.md,
    super.key,
  });

  final Uri? imageUrl;
  final String semanticLabel;

  /// A smaller rendition of the same picture, drawn while [imageUrl] is not yet
  /// on hand.
  ///
  /// A page a reader came from a list has the list's rendition of that work
  /// already — that is the picture they tapped — so drawing it keeps the
  /// picture on screen rather than emptying the frame the full cover is about
  /// to fill. It is the same picture at fewer pixels, and the full cover
  /// replaces it in place; null when the caller has no such rendition to offer.
  final Uri? previewUrl;

  final BoxFit fit;

  /// Which part of the cover the box keeps when the two do not share a shape.
  /// A portrait drawn in a square box is a head, and a head is at the top of
  /// the picture rather than in the middle of it.
  final Alignment alignment;
  final double borderRadius;

  /// Ceiling for a decoded cover. A window wide enough to ask for more than this
  /// is being laid out for a display that cannot show it, and the decode is what
  /// costs.
  static const int _maximumDecodedWidth = 4096;

  /// Floor for a decoded cover, so a widget measured at one or two logical
  /// pixels does not decode a thumbnail.
  static const int _minimumDecodedWidth = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: MioColors.surfaceHigh,
        child: uri == null
            ? _ImageFallback(
                icon: Icons.image_not_supported_outlined,
                label: '$semanticLabel：暂无图片',
              )
            : LayoutBuilder(
                builder: (context, constraints) => _cover(
                  context: context,
                  ref: ref,
                  uri: uri,
                  decodedWidth: _decodedWidth(context, constraints),
                ),
              ),
      ),
    );
  }

  Widget _cover({
    required BuildContext context,
    required WidgetRef ref,
    required Uri uri,
    required int? decodedWidth,
  }) {
    // Read without watching: the bytes are the same list the pipeline handed
    // out, and the tile that has them needs nothing from the provider.
    final cache = ref.watch(imageMemoryCacheProvider);
    final held = cache.read(uri);
    if (held != null) {
      return _ImageBytes(
        bytes: held,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        decodedWidth: decodedWidth,
      );
    }
    final cover = ref.watch(imageBytesProvider(uri));
    final renditionUri = previewUrl;
    // Asked for as well, so that a cover still on its way can be drawn as the
    // rendition the caller offered instead of as the block the rest of the app
    // loads with.
    final rendition = renditionUri == null
        ? null
        : ref.watch(imageBytesProvider(renditionUri));
    final bytes =
        cover.value ??
        (renditionUri == null ? null : cache.read(renditionUri)) ??
        rendition?.value;
    if (bytes != null) {
      return _ImageBytes(
        bytes: bytes,
        fit: fit,
        alignment: alignment,
        semanticLabel: semanticLabel,
        decodedWidth: decodedWidth,
        // A cover being read for the first time arrives rather than appears —
        // unless a rendition stood in for it, which is the same picture already
        // on screen and nothing a fade would announce.
        fadeIn: renditionUri == null,
      );
    }
    if (cover.hasError && (rendition == null || rendition.hasError)) {
      final error = cover.error!;
      return shouldUseWebDirectImageFallback(
            isWeb: kIsWeb,
            uri: uri,
            error: error,
          )
          ? _WebDirectImageFallback(
              uri: uri,
              fit: fit,
              alignment: alignment,
              semanticLabel: semanticLabel,
              decodedWidth: decodedWidth,
            )
          : _ImageFallback(
              icon: Icons.broken_image_outlined,
              label: '$semanticLabel：图片加载失败',
            );
    }
    return _ImageSkeleton(semanticLabel: semanticLabel);
  }

  /// Physical width to decode at, from the box the cover is being given: the
  /// pixels on screen are the pixels worth decoding.
  static int? _decodedWidth(BuildContext context, BoxConstraints constraints) {
    if (!constraints.hasBoundedWidth) return null;
    final logical = constraints.maxWidth;
    if (!logical.isFinite || logical <= 0) return null;
    final physical = (logical * MediaQuery.devicePixelRatioOf(context)).round();
    if (physical <= 0) return null;
    return physical.clamp(_minimumDecodedWidth, _maximumDecodedWidth);
  }

  /// Physical width to decode at for a cover drawn in a box [width] logical
  /// pixels wide, which is what [MioImage] works out for itself from the box it
  /// is given. A widget drawing a cover outside a box of its own — a picture
  /// being flown between two pages, sized by the animation rather than by a
  /// layout — asks with the widest box the cover will be seen in.
  static int? decodeWidthFor(BuildContext context, double width) {
    return _decodedWidth(context, BoxConstraints.tightFor(width: width));
  }
}

/// A cover drawn as the page's own backdrop rather than as a picture of
/// something: the same bytes as [MioImage], painted wide and quiet behind a
/// screen's content.
///
/// A backdrop is decoration, so it waits the way decoration should: while the
/// cover is not on hand the band stands on the work's own colour, read from a
/// rendition the app already has — the one a list drew, by way of [previewUrl] —
/// and the cover then resolves into a colour that was already its own instead of
/// appearing out of the page. A cover that cannot be read leaves that colour and
/// nothing else: a skeleton block here would read as content that failed to
/// arrive, and an error icon would be the only thing on the screen shouting.
class MioImageBackdrop extends ConsumerStatefulWidget {
  const MioImageBackdrop({
    required this.imageUrl,
    this.previewUrl,
    this.alignment,
    super.key,
  });

  final Uri? imageUrl;

  /// A rendition of the same picture already on hand elsewhere, which is what
  /// says which colour the band stands on while the cover is on its way. Null
  /// when the caller has no such rendition to offer, in which case the cover
  /// itself is what the colour is read from.
  final Uri? previewUrl;

  /// Which band of the cover the box keeps. Null takes the middle; a page
  /// header usually wants the top, where the cover's subject is.
  final Alignment? alignment;

  @override
  ConsumerState<MioImageBackdrop> createState() => _MioImageBackdropState();
}

class _MioImageBackdropState extends ConsumerState<MioImageBackdrop> {
  /// Whether the cover was on hand the first time this band was drawn. A band
  /// whose cover is already there is simply there, arriving with the page it
  /// belongs to; one that is given its cover later is a cover arriving.
  bool? _coverWasOnHand;

  @override
  Widget build(BuildContext context) {
    final uri = widget.imageUrl;
    if (uri == null) return const SizedBox.shrink();
    final bytes =
        ref.watch(imageMemoryCacheProvider).read(uri) ??
        ref.watch(imageBytesProvider(uri)).value;
    _coverWasOnHand ??= bytes != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final art = bytes == null
            ? null
            : Image.memory(
                bytes,
                fit: BoxFit.cover,
                alignment: widget.alignment ?? Alignment.center,
                cacheWidth: MioImage._decodedWidth(context, constraints),
                gaplessPlayback: true,
                excludeFromSemantics: true,
              );
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The work's own colour, so that a band whose art is still on its
            // way is painted rather than being a hole where the art will go.
            _BackdropColour(uri: widget.previewUrl ?? uri),
            // A cover that was not there when the band was first drawn arrives
            // over that colour, rather than appearing out of the page a whole
            // band at a time.
            if (art != null) _coverWasOnHand! ? art : _FadeIn(child: art),
          ],
        );
      },
    );
  }
}

/// The colour of the cover at [uri], as the floor of the band drawn over it: the
/// work's own colour, so that a band whose art is still on its way is painted
/// rather than being a hole where the art will go.
class _BackdropColour extends ConsumerWidget {
  const _BackdropColour({required this.uri});

  final Uri uri;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colour = ref.watch(coverColourProvider(uri)).value;
    return colour == null ? const SizedBox.shrink() : ColoredBox(color: colour);
  }
}

/// [child] arriving over whatever is already drawn, rather than appearing.
class _FadeIn extends StatelessWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MioMotion.resolve(context, MioDurations.short),
      curve: Curves.easeOut,
      builder: (context, opacity, child) =>
          Opacity(opacity: opacity, child: child),
      child: child,
    );
  }
}

/// A cover that has not arrived: the skeleton block the app loads with, filling
/// the shape the poster will land in, with the shared shimmer sweeping across it
/// while the bytes are on their way. It carries the loading label so assistive
/// technology hears what the old spinner used to say.
class _ImageSkeleton extends StatelessWidget {
  const _ImageSkeleton({required this.semanticLabel});

  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel：图片加载中',
      image: true,
      child: const MioPlaceholder.expand(radius: 0),
    );
  }
}

class _WebDirectImageFallback extends StatelessWidget {
  const _WebDirectImageFallback({
    required this.uri,
    required this.fit,
    required this.alignment,
    required this.semanticLabel,
    required this.decodedWidth,
  });

  final Uri uri;
  final BoxFit fit;
  final Alignment alignment;
  final String semanticLabel;
  final int? decodedWidth;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      uri.toString(),
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
      cacheWidth: decodedWidth,
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
    required this.alignment,
    required this.semanticLabel,
    required this.decodedWidth,
    this.fadeIn = false,
  });

  final Uint8List bytes;
  final BoxFit fit;
  final Alignment alignment;
  final String semanticLabel;
  final int? decodedWidth;
  final bool fadeIn;

  @override
  Widget build(BuildContext context) {
    final image = Image.memory(
      bytes,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
      cacheWidth: decodedWidth,
      semanticLabel: semanticLabel,
      errorBuilder: (_, _, _) => _ImageFallback(
        icon: Icons.broken_image_outlined,
        label: '$semanticLabel：图片解码失败',
      ),
    );
    if (!fadeIn) return image;
    return _FadeIn(child: image);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.icon, required this.label});

  final IconData icon;
  final String label;

  static const double _iconSize = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      child: Center(
        child: Icon(icon, color: MioColors.textSecondary, size: _iconSize),
      ),
    );
  }
}
