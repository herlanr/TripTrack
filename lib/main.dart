import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

/// Einstiegspunkt der App: Flutter ruft zuerst diese Funktion auf.
void main() {
  // runApp baut das übergebene Widget als Wurzel des Widget-Baums auf.
  runApp(const MyApp());
}

/// Das Wurzel-Widget der TripTrack-App.
/// Es ist ein StatelessWidget, weil es selbst keinen veränderlichen Zustand hat.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp stellt alles bereit, was eine Material-App braucht:
    // Theme, Navigation (Navigator) und die Grundstruktur.
    return MaterialApp(
      title: 'TripTrack - Fahrtenbuch',
      debugShowCheckedModeBanner: false, // entfernt das "DEBUG"-Banner oben rechts
      theme: AppTheme.lightTheme, // zentrales Design aus theme/app_theme.dart
      // Startseite der App. Von hier aus wird zu den anderen Screens navigiert.
      home: const WelcomeScreen(),
    );
  }
}