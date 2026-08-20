import 'package:creative_collective/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gothic title renders an uppercase heading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(body: AppTheme.gothicTitle('Creative Collective')),
      ),
    );

    expect(find.text('CREATIVE COLLECTIVE'), findsOneWidget);
  });
}
