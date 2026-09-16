// Basic smoke test: the main screen builds and shows the trip workflow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trip_track/main.dart';
import 'package:trip_track/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows the trip workflow', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('Fahrtenbuch'), findsOneWidget);
    expect(find.text('Start Trip'), findsOneWidget);
    expect(find.text('Stop Trip'), findsOneWidget);
    expect(find.text('No trip started yet.'), findsOneWidget);
  });
}
