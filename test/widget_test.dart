import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sannidhi/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SannidhiApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
