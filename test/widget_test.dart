import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eduprog_firebase/pages/login_page.dart';

void main() {
  testWidgets('Login page renders and validates required fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginPage())),
    );

    expect(find.text('EduOps'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    final submitButton = find.widgetWithText(ElevatedButton, 'Enter Workspace');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
