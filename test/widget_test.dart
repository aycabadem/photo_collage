// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_appflutter/main.dart';
import 'package:my_appflutter/screens/collage_screen.dart';

void main() {
  testWidgets('Collage screen loads when onboarding was seen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initialOnboardingSeen: true));
    await tester.pumpAndSettle();

    expect(find.byType(CollageScreen), findsOneWidget);
    expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
  });
}
