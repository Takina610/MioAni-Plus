import 'package:flutter/material.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/shared/design_system/mio_tokens.dart';

enum MioStateKind { loading, empty, failure, retry, notFound }

class MioStateView extends StatelessWidget {
  const MioStateView.loading({required String label, Key? key})
    : this._(kind: MioStateKind.loading, title: label, key: key);

  const MioStateView.empty({
    required String title,
    required String message,
    Key? key,
  }) : this._(
         kind: MioStateKind.empty,
         title: title,
         message: message,
         key: key,
       );

  const MioStateView.retry({
    required String title,
    required String message,
    required VoidCallback onRetry,
    Key? key,
  }) : this._(
         kind: MioStateKind.retry,
         title: title,
         message: message,
         actionLabel: '重试',
         onAction: onRetry,
         key: key,
       );

  const MioStateView.notFound({required String message, Key? key})
    : this._(
        kind: MioStateKind.notFound,
        title: '页面不存在',
        message: message,
        key: key,
      );

  const MioStateView._({
    required this.kind,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  factory MioStateView.failure({
    required AppFailure failure,
    VoidCallback? onRetry,
    Key? key,
  }) {
    return MioStateView._(
      key: key,
      kind: MioStateKind.failure,
      title: failure.userMessage,
      message: _failureHint(failure.kind),
      actionLabel: onRetry == null ? null : '重试',
      onAction: onRetry,
    );
  }

  final MioStateKind kind;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  static String? _failureHint(AppFailureKind kind) {
    return switch (kind) {
      AppFailureKind.cancelled => null,
      AppFailureKind.offline => '请检查网络连接后重试',
      AppFailureKind.timeout => '内容来源响应时间过长',
      AppFailureKind.rateLimited => '等待一段时间后再试',
      AppFailureKind.notFound => '该内容可能已移动或删除',
      AppFailureKind.forbidden => '内容来源拒绝了当前请求',
      AppFailureKind.upstream => 'MioAni 仍可使用本地功能',
      AppFailureKind.invalidPayload => '为避免显示错误信息，本次内容已被拒绝',
      AppFailureKind.browserPolicy => '可以尝试受支持的浏览器或原生应用',
      AppFailureKind.unknown => '如果问题持续出现，请保留诊断信息',
    };
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      MioStateKind.loading => null,
      MioStateKind.empty => Icons.inbox_outlined,
      MioStateKind.failure => Icons.error_outline,
      MioStateKind.retry => Icons.refresh,
      MioStateKind.notFound => Icons.explore_off_outlined,
    };

    return Semantics(
      container: true,
      liveRegion: kind == MioStateKind.loading || kind == MioStateKind.failure,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(MioSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kind == MioStateKind.loading)
                  const CircularProgressIndicator()
                else
                  Icon(icon, size: 36),
                const SizedBox(height: MioSpacing.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (message != null) ...[
                  const SizedBox(height: MioSpacing.xs),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: MioSpacing.lg),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
