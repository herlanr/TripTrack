import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Nebeneinanderliegende Aktionszeile auf dem Home-Screen mit Stoppuhr-Badge
/// und dem Haupt-Aktionsbutton ("Fahrt Starten" / "Fahrt Beenden").
class HomeActionRow extends StatelessWidget {
  /// Erstellt eine neue HomeActionRow-Instanz.
  const HomeActionRow({
    super.key,
    required this.isActive,
    required this.isBusy,
    required this.elapsedFormattedTime,
    required this.onPressed,
  });

  /// Gibt an, ob aktuell eine Fahrt läuft
  final bool isActive;

  /// Lade-Status bei GPS-Aktionen
  final bool isBusy;

  /// Formatierte Stoppuhr-Zeit (z. B. "1h 23min 30s")
  final String elapsedFormattedTime;

  /// Callback beim Klick auf den Aktionsbutton
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stoppuhr-Badge
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppTheme.stopRed : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 22,
                color: isActive ? AppTheme.stopRed : AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Text(
                elapsedFormattedTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.stopRed : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Aktionsbutton ("Fahrt Starten" / "Fahrt Beenden")
        Expanded(
          child: SizedBox(
            height: 58,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: isActive
                    ? AppTheme.stopRed
                    : AppTheme.primaryLightGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: isBusy ? null : onPressed,
              child: isBusy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isActive ? 'Fahrt Beenden' : 'Fahrt Starten',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
