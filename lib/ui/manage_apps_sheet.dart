import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';

/// Add/remove the apps the Guide watches and set each one's daily budget.
class ManageAppsSheet extends StatelessWidget {
  const ManageAppsSheet({super.key, required this.controller});

  final AppController controller;

  static Future<void> show(BuildContext context, AppController c) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ManageAppsSheet(controller: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final watched = controller.watchedApps;
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text('Apps to watch',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text(
                  'Set a daily budget for each. Your guide messages you when one '
                  'goes over.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (watched.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Nothing watched yet.',
                        style: TextStyle(color: Colors.white38)),
                  )
                else
                  for (final app in watched)
                    _WatchedRow(controller: controller, package: app.packageName),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () => _showPicker(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add an app to watch'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        final options = controller.availableApps();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                Text('Add a distraction',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (options.isEmpty)
                  const Text(
                    'No apps to suggest yet — grant Usage access and use your '
                    'phone a bit first.',
                    style: TextStyle(color: Colors.white54),
                  )
                else
                  for (final option in options)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.label),
                      subtitle: option.usage > Duration.zero
                          ? Text('${option.usage.inMinutes}m today',
                              style: const TextStyle(color: Colors.white38))
                          : null,
                      trailing: const Icon(Icons.add_circle_outline,
                          color: AppTheme.accent),
                      onTap: () async {
                        await controller.addWatchedApp(
                            option.package, option.label);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WatchedRow extends StatelessWidget {
  const _WatchedRow({required this.controller, required this.package});

  final AppController controller;
  final String package;

  @override
  Widget build(BuildContext context) {
    final app = controller.watchedApps.firstWhere(
      (a) => a.packageName == package,
      orElse: () => controller.watchedApps.first,
    );
    final minutes = app.dailyBudget.inMinutes;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(app.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: minutes <= 5
                ? null
                : () => controller.setBudget(
                    package, Duration(minutes: minutes - 5)),
          ),
          SizedBox(
            width: 52,
            child: Text('${minutes}m',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: minutes >= 240
                ? null
                : () => controller.setBudget(
                    package, Duration(minutes: minutes + 5)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            onPressed: () => controller.removeWatchedApp(package),
          ),
        ],
      ),
    );
  }
}
