import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/core/failures/app_failure.dart';
import 'package:mio_ani/src/shared/design_system/mio_state_view.dart';

void main() {
  Future<void> pumpState(WidgetTester tester, Widget child) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('loading and empty states expose explicit semantics', (
    tester,
  ) async {
    await pumpState(tester, const MioStateView.loading(label: '正在加载目录'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载目录'), findsOneWidget);

    await pumpState(
      tester,
      const MioStateView.empty(title: '暂无内容', message: '稍后再来看看'),
    );
    expect(find.text('暂无内容'), findsOneWidget);
    expect(find.text('稍后再来看看'), findsOneWidget);
  });

  testWidgets('failure and retry actions stay presentation-only', (
    tester,
  ) async {
    var retryCount = 0;
    await pumpState(
      tester,
      MioStateView.failure(
        failure: const OfflineFailure(),
        onRetry: () => retryCount += 1,
      ),
    );

    expect(find.text('当前处于离线状态'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(retryCount, 1);

    await pumpState(
      tester,
      MioStateView.retry(
        title: '需要重新加载',
        message: '本组件不决定重试预算',
        onRetry: () => retryCount += 1,
      ),
    );
    expect(find.text('需要重新加载'), findsOneWidget);
  });

  testWidgets('not found state is distinct from an empty collection', (
    tester,
  ) async {
    await pumpState(tester, const MioStateView.notFound(message: '检查链接后重试'));

    expect(find.text('页面不存在'), findsOneWidget);
    expect(find.text('检查链接后重试'), findsOneWidget);
  });
}
