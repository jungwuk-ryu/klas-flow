import 'package:flutter_test/flutter_test.dart';

import 'package:klasflow_example/main.dart';

void main() {
  testWidgets('renders login form', (WidgetTester tester) async {
    await tester.pumpWidget(const KlasflowDemoApp());

    expect(find.text('klasflow Flutter Demo'), findsOneWidget);
    expect(find.text('Student ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in and load data'), findsOneWidget);
  });
}
