import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// Wrapper around the "display over other apps" overlay used for the Jarvis
/// pop-up. Callable from the background isolate (the plugin is registered on
/// that engine in JarvisApplication).
class OverlayService {
  Future<bool> hasPermission() => FlutterOverlayWindow.isPermissionGranted();

  Future<void> requestPermission() async {
    await FlutterOverlayWindow.requestPermission();
  }

  /// Pops the colorful Jarvis card over whatever the user is doing.
  Future<void> showBubble(String message) async {
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
    await FlutterOverlayWindow.showOverlay(
      height: WindowSize.fullCover,
      width: WindowSize.matchParent,
      alignment: OverlayAlignment.center,
      flag: OverlayFlag.defaultFlag,
      overlayTitle: 'Jarvis',
      overlayContent: message,
      enableDrag: false,
    );
    // The overlay isolate needs a moment to attach its listener before we push
    // the message text to it.
    await Future.delayed(const Duration(milliseconds: 400));
    await FlutterOverlayWindow.shareData({'message': message});
  }

  Future<void> close() => FlutterOverlayWindow.closeOverlay();
}
