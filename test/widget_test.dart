import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sks/core/constants/app_strings.dart';
import 'package:sks/main.dart';

void main() {
  testWidgets('App shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.smartKidsShuttle), findsOneWidget);
    expect(
      find.widgetWithText(ElevatedButton, AppStrings.loginButton),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
