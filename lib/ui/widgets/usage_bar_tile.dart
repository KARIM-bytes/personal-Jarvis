import 'package:flutter/material.dart';

import '../../models/watched_app.dart';
import '../../theme/app_theme.dart';

/// Shows one watched app's usage today against its daily budget.
class UsageBarTile extends StatelessWidget {
  const UsageBarTile({
    super.key,
    required this.app,
    required this.usage,
  });

  final WatchedApp app;
  final Duration usage;

  @override
  Widget build(BuildContext context) {
    final used = usage.inMinutes;
    final budget = app.dailyBudget.inMinutes;
    final ratio = budget == 0 ? 1.0 : (used / budget).clamp(0.0, 1.0);
    final over = used > budget;
    final color = over ? AppTheme.danger : AppTheme.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  app.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${used}m / ${budget}m',
                style: TextStyle(
                  color: over ? AppTheme.danger : Colors.white54,
                  fontWeight: over ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 7,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          if (over) ...[
            const SizedBox(height: 4),
            Text(
              '${used - budget} min over budget',
              style: const TextStyle(color: AppTheme.danger, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}
