import 'package:flutter_test/flutter_test.dart';

import 'package:klasflow_example/main.dart';

void main() {
  testWidgets('renders login form', (WidgetTester tester) async {
    await tester.pumpWidget(const KlasflowDemoApp());

    expect(find.text('klasflow 데모 앱'), findsOneWidget);
    expect(find.text('학번 / ID'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인하고 기본 데이터 불러오기'), findsOneWidget);
  });
}
