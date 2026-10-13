import 'package:flutter/material.dart';

import '../models/driver.dart';

/// Renders the driver profile header: avatar circle, full name, and date of birth.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, this.driver});

  final Driver? driver;

  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}.${two(dt.month)}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
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
          const SizedBox(height: 12),
          Text(
            driver?.fullName ?? 'Fahrer Profil',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (driver != null) ...[
            const SizedBox(height: 4),
            Text(
              'Geburtsdatum: ${_formatDate(driver!.dateOfBirth)}',
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
