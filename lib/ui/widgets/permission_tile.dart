import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A single setup step with its grant state. Quiet when granted; the ungranted
/// state carries the only call to action.
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
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.rSm),
      onTap: granted ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.s1, vertical: AppTheme.s1 + 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppTheme.normal,
              curve: AppTheme.ease,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: granted
                    ? AppTheme.accent.withValues(alpha: 0.14)
                    : const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(AppTheme.rSm),
              ),
              child: Icon(icon,
                  size: 20,
                  color: granted ? AppTheme.accent : AppTheme.textSecondary),
            ),
            const SizedBox(width: AppTheme.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textTertiary,
                          height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.s1),
            AnimatedSwitcher(
              duration: AppTheme.fast,
              child: granted
                  ? const Icon(Icons.check_circle_rounded,
                      key: ValueKey('on'), color: AppTheme.accent, size: 22)
                  : Container(
                      key: const ValueKey('off'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Grant',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
