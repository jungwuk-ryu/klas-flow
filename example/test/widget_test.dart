import 'package:flutter_test/flutter_test.dart';

import 'package:klasflow_example/main.dart';

void main() {
  testWidgets('renders login form', (WidgetTester tester) async {
    await tester.pumpWidget(const KlasflowDemoApp());

    expect(find.text('KLAS'), findsWidgets);
    expect(find.text('학번 / ID'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });
}
