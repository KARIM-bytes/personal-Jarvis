import 'package:flutter/material.dart';

import '../../models/guide_message.dart';
import '../../theme/app_theme.dart';

/// One entry in the guide log.
class GuideMessageTile extends StatelessWidget {
  const GuideMessageTile({super.key, required this.message});

  final GuideMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.s1 + 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.25),
                    blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.bolt_rounded,
                color: Color(0xFF03121C), size: 17),
          ),
          const SizedBox(width: AppTheme.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.text,
                    style: const TextStyle(height: 1.4, fontSize: 14.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${message.appLabel} · ${message.minutesSpent}m of ${message.budgetMinutes}m',
                      style: const TextStyle(
                          color: AppTheme.textTertiary, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      _time(message.timestamp),
                      style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ],
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
