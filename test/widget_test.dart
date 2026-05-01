
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dividend_app/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    // ProviderScope로 감싸서 앱을 부팅
    await tester.pumpWidget(
      const ProviderScope(child: DividendApp()),
    );

    // 첫 프레임만 확인 (실제 화면 비동기 로딩이 있을 수 있음)
    await tester.pump();

    // MaterialApp 이 마운트됐는지 확인
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}