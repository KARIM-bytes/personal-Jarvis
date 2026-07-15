import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A single setup step (usage access, notifications) with its grant state.
class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: granted ? AppTheme.accent : Colors.white54),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12.5),
      ),
      trailing: granted
          ? const Icon(Icons.check_circle, color: AppTheme.accent)
          : FilledButton.tonal(
              onPressed: onTap,
              child: const Text('Grant'),
            ),
      onTap: granted ? null : onTap,
    );
  }
}
