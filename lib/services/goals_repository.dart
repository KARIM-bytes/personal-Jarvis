import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../models/message_state.dart';
import '../models/watched_app.dart';

/// Reads and writes everything the user configures: their free-text life goals,
/// the watched apps + budgets, the Guide's per-app message state, and the
/// optional API key. Backed by SharedPreferences so both isolates can reach it.
class GoalsRepository {
  /// Prefs are cached per isolate; reload so the background service sees edits
  /// the UI just saved (budgets, goals, API key) without a restart.
  Future<SharedPreferences> get _prefs async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {
      // Stale cache is still better than failing the read.
    }
    return prefs;
  }

  Future<String> loadGoals() async {
    final prefs = await _prefs;
    return prefs.getString(AppConfig.prefsGoals) ?? '';
  }

  Future<void> saveGoals(String goals) async {
    final prefs = await _prefs;
    await prefs.setString(AppConfig.prefsGoals, goals);
  }

  Future<List<WatchedApp>> loadWatchedApps() async {
    final prefs = await _prefs;
    final raw = prefs.getString(AppConfig.prefsWatchedApps);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => WatchedApp.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveWatchedApps(List<WatchedApp> apps) async {
    final prefs = await _prefs;
    await prefs.setString(
      AppConfig.prefsWatchedApps,
      jsonEncode(apps.map((a) => a.toJson()).toList()),
    );
  }

  Future<Map<String, AppMessageState>> loadMessageState() async {
    final prefs = await _prefs;
    final raw = prefs.getString(AppConfig.prefsMessageState);
    if (raw == null || raw.isEmpty) return {};
    try {
      return AppMessageState.decodeMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> saveMessageState(Map<String, AppMessageState> state) async {
    final prefs = await _prefs;
    await prefs.setString(
      AppConfig.prefsMessageState,
      jsonEncode(AppMessageState.encodeMap(state)),
    );
  }

  /// Clears the "already messaged today" record for one app, so its next
  /// breach can fire immediately (used when the user changes that app's
  /// budget — new rules, fresh slate).
  Future<void> clearMessageStateFor(String packageName) async {
    final state = await loadMessageState();
    if (state.remove(packageName) != null) {
      await saveMessageState(state);
    }
  }

  Future<void> savePendingConversation(ConversationSeed seed) async {
    final prefs = await _prefs;
    await prefs.setString(
        AppConfig.prefsPendingConversation, jsonEncode(seed.toJson()));
  }

  /// Returns and clears any nudge waiting to open as a conversation.
  Future<ConversationSeed?> takePendingConversation() async {
    final prefs = await _prefs;
    final raw = prefs.getString(AppConfig.prefsPendingConversation);
    if (raw == null || raw.isEmpty) return null;
    await prefs.remove(AppConfig.prefsPendingConversation);
    try {
      return ConversationSeed.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<String?> loadApiKey() async {
    final prefs = await _prefs;
    return prefs.getString(AppConfig.prefsApiKey);
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await _prefs;
    if (key.trim().isEmpty) {
      await prefs.remove(AppConfig.prefsApiKey);
    } else {
      await prefs.setString(AppConfig.prefsApiKey, key.trim());
    }
  }
}
