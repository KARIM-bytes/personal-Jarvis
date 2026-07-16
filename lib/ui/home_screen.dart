import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'conversation_screen.dart';
import 'goals_sheet.dart';
import 'manage_apps_sheet.dart';
import 'settings_sheet.dart';
import 'widgets/activity_ring.dart';
import 'widgets/glass.dart';
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
    AppTheme.accentAlt,
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
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) =>
            ConversationScreen(seed: seed, speakOpener: speakOpener),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
              parent: animation,
              curve: AppTheme.ease,
              reverseCurve: Curves.easeInCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.05), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    _inConversation = false;
  }

  bool get _setupComplete =>
      _c.isReady && _c.hasOverlayPermission && _c.batteryUnrestricted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _c,
            builder: (context, _) {
              return RefreshIndicator(
                color: AppTheme.accent,
                backgroundColor: AppTheme.surfaceRaised,
                onRefresh: _c.refresh,
                child: ListView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(
                      AppTheme.s2, AppTheme.s1, AppTheme.s2, 48),
                  children: [
                    Entrance(child: _header()),
                    const SizedBox(height: AppTheme.s3),
                    if (!_setupComplete) ...[
                      Entrance(delayMs: 40, child: _setupCard()),
                      const SizedBox(height: AppTheme.s3),
                    ],
                    Entrance(delayMs: 80, child: const SectionLabel('Today')),
                    Entrance(delayMs: 80, child: _ringsCard()),
                    const SizedBox(height: AppTheme.s3),
                    Entrance(delayMs: 120, child: _primaryButton()),
                    const SizedBox(height: AppTheme.s3),
                    Entrance(
                        delayMs: 160,
                        child: const SectionLabel('Your goals')),
                    Entrance(delayMs: 160, child: _goalsCard()),
                    const SizedBox(height: AppTheme.s3),
                    Entrance(delayMs: 200, child: _talkButton()),
                    const SizedBox(height: AppTheme.s4),
                    Entrance(delayMs: 240, child: _logSection()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Header ---------------------------------------------------------------

  Widget _header() {
    final running = _c.isRunning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_todayLabel().toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text('Summary',
                      style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: AppTheme.textTertiary, size: 22),
              onPressed: () => SettingsSheet.show(context, _c),
            ),
            JarvisOrb(mood: OrbMood.idle, dormant: !running, size: 52),
          ],
        ),
        const SizedBox(height: AppTheme.s2),
        AnimatedSwitcher(
          duration: AppTheme.normal,
          switchInCurve: AppTheme.ease,
          switchOutCurve: AppTheme.ease,
          child: StatusPill(
            key: ValueKey(running),
            label: running
                ? 'Guide active · watching ${_c.watchedApps.length} '
                    '${_c.watchedApps.length == 1 ? 'app' : 'apps'}'
                : 'Guide paused',
            color: running ? const Color(0xFF34D399) : AppTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  // --- Setup ------------------------------------------------------------------

  Widget _setupCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppTheme.s1, AppTheme.s1, AppTheme.s1, 4),
            child: Text('Finish setup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          PermissionTile(
            icon: Icons.query_stats_rounded,
            title: 'Usage access',
            subtitle: 'Read your Digital Wellbeing data.',
            granted: _c.hasUsageAccess,
            onTap: _c.openUsageAccessSettings,
          ),
          PermissionTile(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            subtitle: 'So your guide can reach you.',
            granted: _c.notificationsGranted,
            onTap: _c.requestNotificationPermission,
          ),
          PermissionTile(
            icon: Icons.layers_outlined,
            title: 'Appear on top',
            subtitle: 'Let Jarvis pop up over other apps.',
            granted: _c.hasOverlayPermission,
            onTap: _c.requestOverlayPermission,
          ),
          PermissionTile(
            icon: Icons.bolt_outlined,
            title: 'Battery unrestricted',
            subtitle: 'Keep checks on time in the background.',
            granted: _c.batteryUnrestricted,
            onTap: _c.requestBatteryUnrestricted,
          ),
        ],
      ),
    );
  }

  // --- Rings ------------------------------------------------------------------

  Widget _ringsCard() {
    final watched = _c.watchedApps;
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.s2),
      child: watched.isEmpty
          ? _emptyRings()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Screen time vs budget',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    _quietAction('Manage',
                        onTap: () => ManageAppsSheet.show(context, _c)),
                  ],
                ),
                const SizedBox(height: AppTheme.s2),
                SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: watched.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppTheme.s3),
                    itemBuilder: (context, i) {
                      final app = watched[i];
                      final used = _c.usageFor(app.packageName).inMinutes;
                      final budget = app.dailyBudget.inMinutes;
                      final over = used > budget;
                      final progress = budget == 0 ? 0.0 : used / budget;
                      final color = over
                          ? AppTheme.ringOver
                          : _ringPalette[i % _ringPalette.length];
                      return _ringColumn(
                          app.label, used, budget, progress, color);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _ringColumn(
      String label, int used, int budget, double progress, Color color) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: AppTheme.ease,
            builder: (_, value, __) => ActivityRing(
              progress: value,
              color: color,
              size: 92,
              stroke: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$used',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          fontFeatures: [FontFeature.tabularFigures()])),
                  const Text('min',
                      style: TextStyle(
                          color: AppTheme.textTertiary, fontSize: 10.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.s1 + 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('of $budget min',
              style: TextStyle(color: color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _emptyRings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nothing watched yet',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        const Text(
          'Add the apps that pull you off course, each with a daily budget.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13.5),
        ),
        const SizedBox(height: AppTheme.s2),
        FilledButton.tonalIcon(
          onPressed: () => ManageAppsSheet.show(context, _c),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add an app'),
        ),
      ],
    );
  }

  // --- Actions -----------------------------------------------------------------

  Widget _primaryButton() {
    final running = _c.isRunning;
    return AnimatedContainer(
      duration: AppTheme.normal,
      curve: AppTheme.ease,
      height: 56,
      decoration: BoxDecoration(
        gradient: running ? null : AppTheme.heroGradient,
        color: running ? AppTheme.glassFill : null,
        borderRadius: BorderRadius.circular(AppTheme.rMd - 2),
        border:
            running ? Border.all(color: AppTheme.glassBorder) : null,
        boxShadow: running
            ? const []
            : [
                BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.28),
                    blurRadius: 24,
                    offset: const Offset(0, 6)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.rMd - 2),
          onTap: () async {
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
          child: Center(
            child: AnimatedSwitcher(
              duration: AppTheme.fast,
              child: Row(
                key: ValueKey(running),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 22,
                      color: running
                          ? AppTheme.textSecondary
                          : const Color(0xFF03121C)),
                  const SizedBox(width: AppTheme.s1),
                  Text(
                    running ? 'Pause guide' : 'Activate guide',
                    style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: running
                            ? AppTheme.textSecondary
                            : const Color(0xFF03121C)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _talkButton() {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: AppTheme.rMd - 2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.rMd - 2),
          onTap: () async {
            final seed = await _c.buildPreviewSeed();
            if (mounted) _openConversation(seed);
          },
          child: const SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq_rounded,
                    color: AppTheme.accent, size: 20),
                SizedBox(width: AppTheme.s1),
                Text('Talk to Jarvis',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Goals -------------------------------------------------------------------

  Widget _goalsCard() {
    final goals = _c.goals.trim();
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.rMd),
          onTap: () => GoalsSheet.show(context, _c),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.rSm),
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: AppTheme.s2),
                Expanded(
                  child: Text(
                    goals.isEmpty
                        ? 'Tell your guide what you\'re working toward — it '
                            'judges your screen time against this.'
                        : goals,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: goals.isEmpty
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.s1),
                const Icon(Icons.edit_outlined,
                    color: AppTheme.textTertiary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Log --------------------------------------------------------------------

  Widget _logSection() {
    final messages = _c.messages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          'Guide log',
          trailing: messages.isEmpty
              ? null
              : _quietAction('Clear', onTap: _c.clearMessages),
        ),
        if (messages.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.s3),
            child: Center(
              child: Text('No messages yet. Your time is your own — for now.',
                  style:
                      TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
            ),
          )
        else
          GlassCard(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.s2, vertical: AppTheme.s1 / 2),
            child: Column(
              children: [
                for (var i = 0; i < messages.length; i++) ...[
                  GuideMessageTile(message: messages[i]),
                  if (i != messages.length - 1) const Divider(),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _quietAction(String label, {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ),
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
