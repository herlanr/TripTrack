
import 'dart:async';
import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../theme/app_theme.dart';



Future<void> onLogoutPressed(BuildContext context) async{
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),

      ),
      title: const Row(
        children: [
          Icon(Icons.logout_rounded, color: AppTheme.stopRed, size: 26),
          SizedBox(width: 10),
          Text('Abmelden'),
        ],
      ),
      content: const Text('Möchtest du dich wirklich abmelden?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.stopRed,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Abmelden'),
        ),
      ],
    ),
  );
  if (confirm == true && context.mounted){
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}