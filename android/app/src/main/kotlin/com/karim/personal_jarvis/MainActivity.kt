package com.karim.personal_jarvis

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Expose the foreground-app channel to the UI isolate (used for the
        // "Test a nag" path and permission checks).
        ForegroundAppChannel.register(flutterEngine, this)
    }
}
