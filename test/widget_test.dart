import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trip_track/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders greeting and actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Willkommen. Wer fährt?'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);
  });
}
