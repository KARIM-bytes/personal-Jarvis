import 'package:flutter/services.dart';

/// Bridge to the native Android UsageStats API for foreground-app detection.
///
/// Reading the foreground app requires the special "Usage access" permission,
/// which the user grants from a system settings screen (there is no runtime
/// dialog for it). The method channel is implemented in [MainActivity].
class ForegroundAppService {
  static const MethodChannel _channel =
      MethodChannel('jarvis/foreground_app');

  /// Whether the app currently holds Usage Access permission.
  Future<bool> hasUsageAccess() async {
    try {
      final granted = await _channel.invokeMethod<bool>('hasUsageAccess');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system "Usage access" settings screen so the user can grant it.
  Future<void> openUsageAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openUsageAccessSettings');
    } on PlatformException {
      // Nothing actionable to do if the intent cannot be launched.
    }
  }

  /// Returns the package name of the app currently in the foreground, or null
  /// if it cannot be determined (permission missing, or no recent event).
  Future<String?> currentForegroundPackage() async {
    try {
      return await _channel.invokeMethod<String>('getForegroundApp');
    } on PlatformException {
      return null;
    }
  }
}
