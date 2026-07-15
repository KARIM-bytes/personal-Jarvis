import 'package:flutter/material.dart';

import '../../models/guide_message.dart';
import '../../theme/app_theme.dart';

/// One message the Guide sent, shown in the history.
class GuideMessageTile extends StatelessWidget {
  const GuideMessageTile({super.key, required this.message});

  final GuideMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_alt,
                color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.text, style: const TextStyle(height: 1.35)),
                const SizedBox(height: 4),
                Text(
                  '${message.appLabel} · ${message.minutesSpent}m (budget ${message.budgetMinutes}m) · ${_time(message.timestamp)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
