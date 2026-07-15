import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';
import 'ui/overlay_bubble.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Sets up the port the background isolate uses to push messages to the UI.
  FlutterForegroundTask.initCommunicationPort();
  runApp(const JarvisApp());
}

/// Entry point for the "display over other apps" overlay isolate (referenced by
/// name from the native OverlayService). Renders the floating Jarvis card.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayBubble(),
  ));
}

class JarvisApp extends StatefulWidget {
  const JarvisApp({super.key});

  @override
  State<JarvisApp> createState() => _JarvisAppState();
}

class _JarvisAppState extends State<JarvisApp> {
  final AppController _controller = AppController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jarvis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomeScreen(controller: _controller),
    );
  }
}
