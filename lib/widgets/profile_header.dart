import 'package:flutter/material.dart';

import '../models/driver.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Stellt den Profilkopf für den angemeldeten Fahrer dar (Avatar-Kreis, vollständiger Name, Geburtsdatum, Bearbeiten-Button).
class ProfileHeader extends StatelessWidget {
  /// Erstellt eine neue ProfileHeader-Instanz.
  const ProfileHeader({super.key, this.driver, this.onEditPressed});

  /// Der angemeldete Fahrer
  final Driver? driver;

  /// Callback beim Klick auf "Profil bearbeiten"
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: Color(0xFF2E7D32),
                ),
              ),
              if (driver != null && onEditPressed != null)
                GestureDetector(
                  onTap: onEditPressed,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                driver?.fullName ?? 'Fahrer Profil',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (driver != null && onEditPressed != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: AppTheme.primaryGreen),
                  tooltip: 'Profil bearbeiten',
                  onPressed: onEditPressed,
                ),
              ],
            ],
          ),
          if (driver != null) ...[
            Text(
              'Geburtsdatum: ${formatDate(driver!.dateOfBirth)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
