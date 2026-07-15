import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/nag_event.dart';
import '../models/nag_rule.dart';
import '../services/foreground_app_service.dart';
import '../services/jarvis_task_handler.dart';
import '../services/llm_client.dart';
import '../services/tts_service.dart';

/// Holds all UI-facing state and mediates between the widgets and the
/// background foreground-service isolate.
class MonitorController extends ChangeNotifier {
  final ForegroundAppService _apps = ForegroundAppService();
  final TtsService _tts = TtsService();
  final LlmClient _llm = LlmClient();

  final NagRule rule = NagRule.defaultRule;

  bool _isRunning = false;
  bool _hasUsageAccess = false;
  bool _notificationsGranted = false;
  bool _hasApiKey = false;
  final List<NagEvent> _log = <NagEvent>[];

  bool get isRunning => _isRunning;
  bool get hasUsageAccess => _hasUsageAccess;
  bool get notificationsGranted => _notificationsGranted;
  bool get hasApiKey => _hasApiKey;
  List<NagEvent> get log => List.unmodifiable(_log);

  /// True when everything the service needs has been granted.
  bool get isReady => _hasUsageAccess && _notificationsGranted;

  Future<void> init() async {
    _configureForegroundTask();
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    await refresh();
  }

  void _configureForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: AppConfig.notificationChannelId,
        channelName: AppConfig.notificationChannelName,
        channelDescription: AppConfig.notificationChannelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          AppConfig.pollInterval.inMilliseconds,
        ),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Re-reads permission and service status from the platform.
  Future<void> refresh() async {
    _isRunning = await FlutterForegroundTask.isRunningService;
    _hasUsageAccess = await _apps.hasUsageAccess();
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    _notificationsGranted = notif == NotificationPermission.granted;
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(AppConfig.prefsApiKey);
    _hasApiKey = key != null && key.isNotEmpty;
    notifyListeners();
  }

  void _onTaskData(Object data) {
    final event = NagEvent.fromWire(data);
    if (event != null) {
      _log.insert(0, event);
      notifyListeners();
    }
  }

  // --- Permissions ----------------------------------------------------------

  Future<void> openUsageAccessSettings() async {
    await _apps.openUsageAccessSettings();
    // The user returns via the OS back stack; refresh() is called on resume.
  }

  Future<void> requestNotificationPermission() async {
    await FlutterForegroundTask.requestNotificationPermission();
    await refresh();
  }

  // --- Monitoring lifecycle -------------------------------------------------

  Future<void> toggleMonitoring() async {
    if (_isRunning) {
      await stopMonitoring();
    } else {
      await startMonitoring();
    }
  }

  Future<void> startMonitoring() async {
    await FlutterForegroundTask.startService(
      serviceId: 1001,
      serviceTypes: const [ForegroundServiceTypes.dataSync],
      notificationTitle: 'Jarvis is watching',
      notificationText: 'On duty. Behave yourself.',
      callback: startJarvisCallback,
    );
    _isRunning = await FlutterForegroundTask.isRunningService;
    notifyListeners();
  }

  Future<void> stopMonitoring() async {
    await FlutterForegroundTask.stopService();
    _isRunning = await FlutterForegroundTask.isRunningService;
    notifyListeners();
  }

  // --- Settings / test hooks ------------------------------------------------

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key.trim().isEmpty) {
      await prefs.remove(AppConfig.prefsApiKey);
    } else {
      await prefs.setString(AppConfig.prefsApiKey, key.trim());
    }
    await refresh();
  }

  /// Fires a nag on demand so the loop can be demonstrated without waiting for
  /// the threshold. Routes through the running service when possible, and
  /// otherwise runs the generate-and-speak pipeline locally.
  Future<void> triggerTestNag() async {
    if (_isRunning) {
      FlutterForegroundTask.sendDataToTask('{"type":"test"}');
      return;
    }
    final line = await _llm.generateNag(
      appLabel: rule.appLabel,
      usage: rule.threshold,
    );
    await _tts.speak(line);
    _log.insert(
      0,
      NagEvent(
        appLabel: rule.appLabel,
        appPackage: rule.appPackage,
        message: line,
        timestamp: DateTime.now(),
        continuousUsage: rule.threshold,
      ),
    );
    notifyListeners();
  }

  void clearLog() {
    _log.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    _tts.stop();
    _llm.dispose();
    super.dispose();
  }
}
