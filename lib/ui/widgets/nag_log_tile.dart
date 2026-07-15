import 'package:flutter/material.dart';

import '../../models/nag_event.dart';
import '../../theme/app_theme.dart';

/// One entry in the "times Jarvis called you out" list.
class NagLogTile extends StatelessWidget {
  const NagLogTile({super.key, required this.event});

  final NagEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.campaign, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"${event.message}"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.appLabel} · ${event.continuousUsage.inMinutes} min · ${_time(event.timestamp)}',
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
