import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mio_ani/src/features/translation/application/translation_providers.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

/// Where on a page a translation is being offered, which decides how much room
/// the button and the translation take.
enum TranslationVariant {
  /// Under a title, where the button is a pill on the title's own line and the
  /// translation sits under both titles as a quoted block.
  title,

  /// On a section's heading, with the translation under the body it belongs to.
  summary,

  /// Beside a row of tags, where both the button and the translation stay small
  /// enough not to become the largest thing in the record.
  tags;

  /// Space between the button and what it produced.
  double get gap => switch (this) {
    TranslationVariant.title => MioSpacing.sm,
    TranslationVariant.summary => MioSpacing.md,
    TranslationVariant.tags => MioSpacing.xs,
  };

  String get label => switch (this) {
    TranslationVariant.title => '翻译标题',
    TranslationVariant.summary => '翻译简介',
    TranslationVariant.tags => '翻译标签',
  };
}

/// Whether these widgets belong on the page at all.
///
/// [offered] is the caller's judgement about the text — whether it is written
/// in something the reader may not read — and it is the caller's because only
/// the caller knows what the text is. A work's title can be settled by the
/// source's filing (see `workTitleReadsForeign`), while a synopsis has nothing
/// but its own characters to go on; a widget that guessed would have to guess
/// the same way for both.
///
/// A build with no key cannot ask at all, and that is settled here rather than
/// by every caller: a page in a build without credentials offers nothing,
/// whatever the text is.
bool _isOffered(WidgetRef ref, {required bool offered}) {
  return offered && ref.watch(translationConfiguredProvider);
}

/// The offer to translate one piece of text, with its answer under it.
///
/// This is for the places where the two belong on the same line — a title, a
/// row of tags. Where the translation wants to land somewhere else on the page,
/// a caller uses [MioTranslateButton] and [MioTranslationOutput] separately:
/// both watch the same text, so the button on a heading and the translation
/// under the body it names stay one thing however far apart they are drawn.
class MioTranslateAction extends ConsumerWidget {
  const MioTranslateAction({
    required this.source,
    required this.variant,
    required this.offered,
    this.alignment = CrossAxisAlignment.start,
    super.key,
  });

  /// The text to translate. It is also the translation's identity: the same
  /// text is the same translation, wherever on the page it is asked for.
  final String source;
  final TranslationVariant variant;

  /// Whether the text is worth translating, which the caller decides.
  final bool offered;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isOffered(ref, offered: offered)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: alignment,
      children: <Widget>[
        MioTranslateButton(source: source, variant: variant, offered: offered),
        MioTranslationOutput(
          source: source,
          variant: variant,
          offered: offered,
        ),
      ],
    );
  }
}

/// The button that asks for [source] in Chinese, and puts it away again.
class MioTranslateButton extends ConsumerWidget {
  const MioTranslateButton({
    required this.source,
    required this.variant,
    required this.offered,
    super.key,
  });

  final String source;
  final TranslationVariant variant;

  /// Whether the text is worth translating, which the caller decides.
  final bool offered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isOffered(ref, offered: offered)) return const SizedBox.shrink();
    final state = ref.watch(textTranslationProvider(source));
    final controller = ref.read(textTranslationProvider(source).notifier);
    final compact = variant == TranslationVariant.tags;
    final running = state.isRunning;
    final label = state.labelFor(variant.label);
    // The button's own text is its name; an explicit label on top of it made a
    // screen reader say `翻译简介, 翻译简介`.
    return Semantics(
      button: true,
      enabled: !running,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          // A press that arrives while a request is out is not a second
          // request, it is a finger on a button that has already done its job.
          onTap: running ? null : controller.toggle,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: BoxConstraints(minHeight: compact ? 28 : 32),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? MioSpacing.xs : MioSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: MioColors.accent.withValues(alpha: running ? 0.06 : 0.1),
              border: Border.all(
                color: MioColors.accent.withValues(
                  alpha: running ? 0.18 : 0.24,
                ),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.translate,
                  size: compact ? 13 : 14,
                  color: MioColors.accent.withValues(alpha: running ? 0.7 : 1),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: MioColors.accent.withValues(
                      alpha: running ? 0.7 : 1,
                    ),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the button produced: the translation, or the reason there is none.
///
/// It draws nothing at all until there is something to say, so a caller puts it
/// where the translation belongs and lets it take up no room until then — and
/// leave none behind when it is hidden again.
class MioTranslationOutput extends ConsumerWidget {
  const MioTranslationOutput({
    required this.source,
    required this.variant,
    required this.offered,
    super.key,
  });

  final String source;
  final TranslationVariant variant;

  /// Whether the text was worth translating. It is what hid the button, and it
  /// is what keeps a translation that has already been shown from being
  /// orphaned by the button disappearing above it.
  final bool offered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isOffered(ref, offered: offered)) return const SizedBox.shrink();
    final state = ref.watch(textTranslationProvider(source));
    final controller = ref.read(textTranslationProvider(source).notifier);
    final failure = state.failure;
    if (state.hasFailed && failure != null) {
      return Padding(
        padding: EdgeInsets.only(top: variant.gap),
        child: _TranslationNotice(
          message: failure.message,
          variant: variant,
          onRetry: () => controller.reveal().ignore(),
        ),
      );
    }
    final text = state.text;
    if (!state.isShown || text == null) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: variant.gap),
      child: _TranslationText(text: text, variant: variant),
    );
  }
}

/// The translation, under the words it came from.
///
/// A quoted block rather than a replacement: the reader asked what something
/// says, and both the original and the answer stay in front of them to compare.
/// The accent rule down its left edge is what marks it as the app's own voice
/// rather than the source's.
class _TranslationText extends StatelessWidget {
  const _TranslationText({required this.text, required this.variant});

  final String text;
  final TranslationVariant variant;

  @override
  Widget build(BuildContext context) {
    final compact = variant == TranslationVariant.tags;
    final vertical = compact ? MioSpacing.xs : MioSpacing.sm;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        MioSpacing.sm,
        vertical,
        MioSpacing.sm,
        vertical,
      ),
      decoration: BoxDecoration(
        color: MioColors.accent.withValues(alpha: 0.07),
        border: Border(
          left: BorderSide(
            color: MioColors.accent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(MioRadii.sm),
          bottomRight: Radius.circular(MioRadii.sm),
        ),
      ),
      child: Semantics(
        liveRegion: true,
        child: SelectableText(
          text,
          style: TextStyle(
            color: MioColors.textPrimary.withValues(alpha: 0.9),
            fontSize: compact ? 12 : 14,
            height: compact ? 1.5 : 1.7,
          ),
        ),
      ),
    );
  }
}

/// A translation that did not come back, with the reason and the way to ask
/// again. It is drawn where the translation would have been, so the page does
/// not move when a retry succeeds.
class _TranslationNotice extends StatelessWidget {
  const _TranslationNotice({
    required this.message,
    required this.variant,
    required this.onRetry,
  });

  final String message;
  final TranslationVariant variant;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        MioSpacing.sm,
        MioSpacing.xs,
        MioSpacing.xs,
        MioSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: MioColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MioRadii.sm),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: MioColors.error,
                fontSize: variant == TranslationVariant.tags ? 11 : 12,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: MioColors.accent,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: MioSpacing.sm),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}
