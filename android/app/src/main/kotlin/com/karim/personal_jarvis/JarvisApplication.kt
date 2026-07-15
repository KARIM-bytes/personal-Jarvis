package com.karim.personal_jarvis

import android.app.Application
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.engine.FlutterEngine

/**
 * flutter_foreground_task spins up a *separate* FlutterEngine for the
 * background task isolate, and that engine does not auto-register app plugins.
 * We hook its lifecycle here so the `jarvis/usage` channel is available inside
 * the background isolate — without it, the periodic goal check could never read
 * the usage data.
 */
class JarvisApplication : Application() {
    private val taskLifecycleListener =
        object : FlutterForegroundTaskLifecycleListener {
            override fun onEngineCreate(flutterEngine: FlutterEngine?) {
                flutterEngine?.let {
                    UsageChannel.register(it, applicationContext)
                }
            }

            override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}

            override fun onTaskRepeatEvent() {}

            override fun onTaskDestroy() {}

            override fun onEngineWillDestroy() {}
        }

    override fun onCreate() {
        super.onCreate()
        FlutterForegroundTaskPlugin.addTaskLifecycleListener(taskLifecycleListener)
    }
}
