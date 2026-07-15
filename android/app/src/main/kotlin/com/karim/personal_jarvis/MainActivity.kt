package com.karim.personal_jarvis

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Expose the usage channel to the UI isolate (dashboard, app picker,
        // permission checks, message preview).
        UsageChannel.register(flutterEngine, this)
    }
}
