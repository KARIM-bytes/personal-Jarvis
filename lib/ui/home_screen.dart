import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'conversation_screen.dart';
import 'goals_sheet.dart';
import 'manage_apps_sheet.dart';
import 'settings_sheet.dart';
import 'widgets/activity_ring.dart';
import 'widgets/guide_message_tile.dart';
import 'widgets/jarvis_orb.dart';
import 'widgets/permission_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppController get _c => widget.controller;
  bool _inConversation = false;

  static const List<Color> _ringPalette = [
    AppTheme.ringStand,
    AppTheme.ringMove,
    AppTheme.ringExercise,
    Color(0xFF7A5CFF),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPending());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _c.refresh();
      _checkPending();
    }
  }

  /// If a breach queued a nudge, open it as a conversation. The overlay already
  /// spoke the opener, so don't repeat it here.
  Future<void> _checkPending() async {
    if (_inConversation) return;
    final seed = await _c.takePendingConversation();
    if (seed != null && mounted) {
      _openConversation(seed, speakOpener: false);
    }
  }

  Future<void> _openConversation(
    ConversationSeed seed, {
    bool speakOpener = true,
  }) async {
    _inConversation = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ConversationScreen(seed: seed, speakOpener: speakOpener),
      ),
    );
    _inConversation = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _c,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: _c.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _summaryHeader(),
                  const SizedBox(height: 18),
                  if (!_c.isReady ||
                      !_c.hasOverlayPermission ||
                      !_c.batteryUnrestricted) ...[
                    _setupCard(),
                    const SizedBox(height: 16),
                  ],
                  _ringsCard(),
                  const SizedBox(height: 16),
                  _primaryButton(),
                  const SizedBox(height: 16),
                  _goalsCard(),
                  const SizedBox(height: 16),
                  _previewButton(),
                  const SizedBox(height: 24),
                  _messagesSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Summary',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                _todayLabel(),
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white54),
          onPressed: () => SettingsSheet.show(context, _c),
        ),
        const SizedBox(width: 2),
        // Breathing while the guide runs; dims when paused. Never still.
        JarvisOrb(mood: OrbMood.idle, dormant: !_c.isRunning, size: 52),
      ],
    );
  }

  Widget _ringsCard() {
    final watched = _c.watchedApps;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Today',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ManageAppsSheet.show(context, _c),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (watched.isEmpty)
              _emptyRings()
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: watched.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 18),
                  itemBuilder: (context, i) {
                    final app = watched[i];
                    final used = _c.usageFor(app.packageName).inMinutes;
                    final budget = app.dailyBudget.inMinutes;
                    final over = used > budget;
                    final progress = budget == 0 ? 0.0 : used / budget;
                    final color = over
                        ? AppTheme.ringOver
                        : _ringPalette[i % _ringPalette.length];
                    return _ringColumn(app.label, used, budget, progress, color);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ringColumn(
      String label, int used, int budget, double progress, Color color) {
    return SizedBox(
      width: 104,
      child: Column(
        children: [
          ActivityRing(
            progress: progress,
            color: color,
            size: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$used',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
                const Text('min',
                    style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('$budget min goal',
              style: TextStyle(color: color, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _emptyRings() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add the apps that pull you off course, each with a daily budget.',
            style: TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => ManageAppsSheet.show(context, _c),
            icon: const Icon(Icons.add),
            label: const Text('Add an app'),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton() {
    final running = _c.isRunning;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: running ? AppTheme.surfaceRaised : AppTheme.accent,
          foregroundColor: running ? Colors.white : Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
        label: Text(running ? 'Guide is on — pause' : 'Activate guide',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        onPressed: () async {
          await _c.toggleGuide();
          if (!mounted) return;
          if (_c.isRunning && !_c.isReady) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Running, but grant Usage access so your guide can see your time.'),
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
              child: Text('Setup',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            PermissionTile(
              icon: Icons.query_stats,
              title: 'Usage access',
              subtitle: 'Lets your guide read your Digital Wellbeing data.',
              granted: _c.hasUsageAccess,
              onTap: _c.openUsageAccessSettings,
            ),
            PermissionTile(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              subtitle: 'So your guide can text you.',
              granted: _c.notificationsGranted,
              onTap: _c.requestNotificationPermission,
            ),
            PermissionTile(
              icon: Icons.picture_in_picture_alt_outlined,
              title: 'Jarvis pop-up',
              subtitle: 'Let Jarvis appear over other apps to talk to you.',
              granted: _c.hasOverlayPermission,
              onTap: _c.requestOverlayPermission,
            ),
            PermissionTile(
              icon: Icons.battery_charging_full,
              title: 'Battery unrestricted',
              subtitle: 'Stops Android from delaying Jarvis\'s checks.',
              granted: _c.batteryUnrestricted,
              onTap: _c.requestBatteryUnrestricted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalsCard() {
    final goals = _c.goals.trim();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => GoalsSheet.show(context, _c),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_outlined, color: AppTheme.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your goals',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      goals.isEmpty
                          ? 'Tap to tell your guide what you\'re working toward.'
                          : goals,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                        color: goals.isEmpty ? Colors.white54 : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: AppTheme.accentDim),
        foregroundColor: AppTheme.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.graphic_eq),
      label: const Text('Talk to Jarvis now'),
      onPressed: () async {
        final seed = await _c.buildPreviewSeed();
        if (mounted) _openConversation(seed);
      },
    );
  }

  Widget _messagesSection() {
    final messages = _c.messages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Guide messages',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            if (messages.isNotEmpty)
              TextButton(
                  onPressed: _c.clearMessages, child: const Text('Clear')),
          ],
        ),
        const SizedBox(height: 4),
        if (messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No messages yet. Your time is your own — for now.',
                  style: TextStyle(color: Colors.white38)),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < messages.length; i++) ...[
                    GuideMessageTile(message: messages[i]),
                    if (i != messages.length - 1)
                      const Divider(height: 1, color: Colors.white10),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _todayLabel() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
