import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mio_ani/src/features/imports/application/import_providers.dart';
import 'package:mio_ani/src/features/imports/data/import_service.dart';
import 'package:mio_ani/src/features/imports/presentation/import_page.dart';

void main() {
  testWidgets('公开收藏导入页面提供来源、用户名和取消语义', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          importServiceProvider.overrideWithValue(const ImportService({})),
        ],
        child: const MaterialApp(home: ImportPage()),
      ),
    );
    expect(find.text('导入公开收藏'), findsOneWidget);
    expect(find.text('公开用户名'), findsOneWidget);
    expect(find.text('读取公开收藏'), findsOneWidget);
    expect(find.text('只作为查询输入，不作为账号主键'), findsOneWidget);
  });
}
