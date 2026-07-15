import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../config/app_config.dart';
import '../models/app_usage.dart';
import '../models/chat_message.dart';
import '../models/guide_message.dart';
import '../models/watched_app.dart';
import '../services/goals_repository.dart';
import '../services/guide_task_handler.dart';
import '../services/llm_client.dart';
import '../services/overlay_service.dart';
import '../services/usage_stats_service.dart';

/// A candidate app for the "add distraction" picker.
typedef AppOption = ({String package, String label, Duration usage});

/// Holds all UI state and mediates between the widgets and the background
/// foreground-service isolate that runs the goal check.
class AppController extends ChangeNotifier {
  final UsageStatsService _usage = UsageStatsService();
  final GoalsRepository _repo = GoalsRepository();
  final LlmClient _llm = LlmClient();
  final OverlayService _overlay = OverlayService();

  bool _isRunning = false;
  bool _hasUsageAccess = false;
  bool _notificationsGranted = false;
  bool _hasOverlayPermission = false;
  bool _hasApiKey = false;
  String _goals = '';
  List<WatchedApp> _watchedApps = [];
  UsageSnapshot _snapshot = UsageSnapshot(const []);
  final List<GuideMessage> _messages = [];

  bool get isRunning => _isRunning;
  bool get hasUsageAccess => _hasUsageAccess;
  bool get notificationsGranted => _notificationsGranted;
  bool get hasOverlayPermission => _hasOverlayPermission;
  bool get hasApiKey => _hasApiKey;
  bool get isReady => _hasUsageAccess && _notificationsGranted;
  String get goals => _goals;
  List<WatchedApp> get watchedApps => List.unmodifiable(_watchedApps);
  List<GuideMessage> get messages => List.unmodifiable(_messages);

  Duration usageFor(String packageName) => _snapshot.usageFor(packageName);

  Future<void> init() async {
    _configureForegroundTask();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    await refresh();
  }

  void _configureForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'guide_channel',
        channelName: 'Your guide',
        channelDescription: 'Messages from your personal guide.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        onlyAlertOnce: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          AppConfig.checkInterval.inMilliseconds,
        ),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  Future<void> refresh() async {
    _isRunning = await FlutterForegroundTask.isRunningService;
    _hasUsageAccess = await _usage.hasUsageAccess();
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    _notificationsGranted = notif == NotificationPermission.granted;
    _hasOverlayPermission = await _overlay.hasPermission();
    _goals = await _repo.loadGoals();
    _watchedApps = await _repo.loadWatchedApps();
    _hasApiKey = (await _repo.loadApiKey())?.isNotEmpty ?? false;
    if (_hasUsageAccess) {
      _snapshot = await _usage.todayUsage();
    }
    notifyListeners();
  }

  void _onTaskData(Object data) {
    final message = GuideMessage.fromWire(data);
    if (message != null) {
      _messages.insert(0, message);
      notifyListeners();
    }
  }

  // --- Permissions ----------------------------------------------------------

  Future<void> openUsageAccessSettings() => _usage.openUsageAccessSettings();

  Future<void> requestNotificationPermission() async {
    await FlutterForegroundTask.requestNotificationPermission();
    await refresh();
  }

  Future<void> requestOverlayPermission() async {
    await _overlay.requestPermission();
    // Returns via the OS back stack; refresh() runs on resume.
  }

  /// Any nudge waiting to open as a conversation (from a breach). Cleared once
  /// returned.
  Future<ConversationSeed?> takePendingConversation() =>
      _repo.takePendingConversation();

  // --- Goals & watched apps -------------------------------------------------

  Future<void> saveGoals(String goals) async {
    _goals = goals;
    await _repo.saveGoals(goals);
    notifyListeners();
  }

  /// Apps to offer in the picker: everything used today (real labels), plus any
  /// common distractions not yet seen, minus apps already being watched.
  List<AppOption> availableApps() {
    final watchedPackages = _watchedApps.map((a) => a.packageName).toSet();
    final options = <String, AppOption>{};

    for (final app in _snapshot.apps) {
      if (watchedPackages.contains(app.packageName)) continue;
      options[app.packageName] =
          (package: app.packageName, label: app.label, usage: app.usage);
    }
    AppConfig.commonDistractions.forEach((package, label) {
      if (watchedPackages.contains(package) || options.containsKey(package)) {
        return;
      }
      options[package] = (package: package, label: label, usage: Duration.zero);
    });

    final list = options.values.toList()
      ..sort((a, b) => b.usage.compareTo(a.usage));
    return list;
  }

  Future<void> addWatchedApp(String package, String label) async {
    if (_watchedApps.any((a) => a.packageName == package)) return;
    _watchedApps = [
      ..._watchedApps,
      WatchedApp(
        packageName: package,
        label: label,
        dailyBudget: const Duration(minutes: AppConfig.defaultBudgetMinutes),
      ),
    ];
    await _repo.saveWatchedApps(_watchedApps);
    notifyListeners();
  }

  Future<void> setBudget(String package, Duration budget) async {
    _watchedApps = _watchedApps
        .map((a) =>
            a.packageName == package ? a.copyWith(dailyBudget: budget) : a)
        .toList();
    await _repo.saveWatchedApps(_watchedApps);
    notifyListeners();
  }

  Future<void> removeWatchedApp(String package) async {
    _watchedApps =
        _watchedApps.where((a) => a.packageName != package).toList();
    await _repo.saveWatchedApps(_watchedApps);
    notifyListeners();
  }

  // --- Guide lifecycle ------------------------------------------------------

  Future<void> toggleGuide() async {
    if (_isRunning) {
      await FlutterForegroundTask.stopService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 2001,
        serviceTypes: const [ForegroundServiceTypes.dataSync],
        notificationTitle: 'Guiding you toward your goals',
        notificationText: 'Watching your time so it serves what matters.',
        callback: startGuideCallback,
      );
    }
    _isRunning = await FlutterForegroundTask.isRunningService;
    notifyListeners();
  }

  // --- Settings / preview ---------------------------------------------------

  Future<void> setApiKey(String key) async {
    await _repo.saveApiKey(key);
    _hasApiKey = key.trim().isNotEmpty;
    notifyListeners();
  }

  /// Builds a conversation seed for the "preview" button, so the user can talk
  /// to Jarvis on demand during setup without waiting for a real breach.
  Future<ConversationSeed> buildPreviewSeed() async {
    final app = _watchedApps.isNotEmpty
        ? _watchedApps.first
        : const WatchedApp(
            packageName: 'com.instagram.android',
            label: 'Instagram',
            dailyBudget: Duration(minutes: 30),
          );
    final actual = usageFor(app.packageName);
    final usage = actual > app.dailyBudget
        ? actual
        : app.dailyBudget + const Duration(minutes: 15);
    final opener = await _llm.composeGuideMessage(
      appLabel: app.label,
      minutesSpent: usage.inMinutes,
      budgetMinutes: app.dailyBudget.inMinutes,
    );
    return ConversationSeed(
      appLabel: app.label,
      appPackage: app.packageName,
      minutesSpent: usage.inMinutes,
      budgetMinutes: app.dailyBudget.inMinutes,
      opener: opener,
    );
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _llm.dispose();
    super.dispose();
  }
}
