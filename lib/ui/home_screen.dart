import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../state/monitor_controller.dart';
import '../theme/app_theme.dart';
import 'settings_sheet.dart';
import 'widgets/jarvis_core.dart';
import 'widgets/nag_log_tile.dart';
import 'widgets/permission_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final MonitorController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  MonitorController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh permissions when returning from a system settings screen.
    if (state == AppLifecycleState.resumed) {
      _c.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JARVIS',
          style: TextStyle(letterSpacing: 6, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => SettingsSheet.show(context, _c),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: _c.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _statusHeader(),
                const SizedBox(height: 24),
                _primaryButton(),
                const SizedBox(height: 20),
                if (!_c.isReady) ...[
                  _setupCard(),
                  const SizedBox(height: 16),
                ],
                _ruleCard(),
                const SizedBox(height: 16),
                _testButton(),
                const SizedBox(height: 24),
                _logSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusHeader() {
    final running = _c.isRunning;
    return Column(
      children: [
        const SizedBox(height: 8),
        JarvisCore(active: running),
        const SizedBox(height: 16),
        Text(
          running ? 'On duty' : 'Standing by',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          running
              ? 'Watching for ${AppConfig.watchedLabel} binges.'
              : 'Activate to let Jarvis watch over your shoulder.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _primaryButton() {
    final running = _c.isRunning;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: running ? AppTheme.danger : AppTheme.accent,
          foregroundColor: running ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(running ? Icons.stop_rounded : Icons.play_arrow_rounded),
        label: Text(
          running ? 'Stand down' : 'Activate Jarvis',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          await _c.toggleMonitoring();
          if (!mounted) return;
          if (_c.isRunning && !_c.isReady) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Running, but grant Usage Access so Jarvis can see your apps.',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _setupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text(
                'Setup',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            PermissionTile(
              icon: Icons.query_stats,
              title: 'Usage access',
              subtitle: 'Lets Jarvis see which app is in front.',
              granted: _c.hasUsageAccess,
              onTap: _c.openUsageAccessSettings,
            ),
            PermissionTile(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              subtitle: 'Required for the background service.',
              granted: _c.notificationsGranted,
              onTap: _c.requestNotificationPermission,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ruleCard() {
    final rule = _c.rule;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.gpp_maybe, color: AppTheme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active rule',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No more than ${rule.threshold.inMinutes} min on ${rule.appLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Chip(
              label: Text('v1'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _testButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppTheme.accentDim),
        foregroundColor: AppTheme.accent,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.volume_up_outlined),
      label: const Text('Test a nag now'),
      onPressed: () => _c.triggerTestNag(),
    );
  }

  Widget _logSection() {
    final log = _c.log;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Nag log',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const Spacer(),
            if (log.isNotEmpty)
              TextButton(
                onPressed: _c.clearLog,
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (log.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No nags yet. A model citizen — for now.',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < log.length; i++) ...[
                    NagLogTile(event: log[i]),
                    if (i != log.length - 1)
                      const Divider(height: 1, color: Colors.white10),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
