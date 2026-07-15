import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'conversation_screen.dart';
import 'goals_sheet.dart';
import 'manage_apps_sheet.dart';
import 'settings_sheet.dart';
import 'widgets/guide_message_tile.dart';
import 'widgets/jarvis_core.dart';
import 'widgets/permission_tile.dart';
import 'widgets/usage_bar_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  AppController get _c => widget.controller;
  bool _inConversation = false;

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

  /// If a breach queued a nudge, open it as a conversation.
  Future<void> _checkPending() async {
    if (_inConversation) return;
    final seed = await _c.takePendingConversation();
    if (seed != null && mounted) _openConversation(seed);
  }

  Future<void> _openConversation(ConversationSeed seed) async {
    _inConversation = true;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ConversationScreen(seed: seed)),
    );
    _inConversation = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JARVIS',
            style: TextStyle(letterSpacing: 6, fontWeight: FontWeight.w700)),
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
                if (!_c.isReady || !_c.hasOverlayPermission) ...[
                  _setupCard(),
                  const SizedBox(height: 16),
                ],
                _goalsCard(),
                const SizedBox(height: 16),
                _watchedCard(),
                const SizedBox(height: 16),
                _previewButton(),
                const SizedBox(height: 24),
                _messagesSection(),
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
        Text(running ? 'Guiding you' : 'Paused',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          running
              ? 'Watching your time so it serves your goals.'
              : 'Turn on your guide to get nudged back on track.',
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
        label: Text(running ? 'Pause guide' : 'Activate guide',
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

  Widget _watchedCard() {
    final watched = _c.watchedApps;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Watched apps',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ManageAppsSheet.show(context, _c),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Manage'),
                ),
              ],
            ),
            if (watched.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add the apps that pull you off course, each with a daily '
                      'budget.',
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
              )
            else
              for (final app in watched)
                UsageBarTile(app: app, usage: _c.usageFor(app.packageName)),
          ],
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
      icon: const Icon(Icons.chat_bubble_outline),
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
}
