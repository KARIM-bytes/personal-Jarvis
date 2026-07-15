package com.karim.personal_jarvis

import android.app.Application
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskPlugin
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.engine.FlutterEngine

/**
 * flutter_foreground_task spins up a *separate* FlutterEngine for the
 * background task isolate, and that engine does not auto-register app plugins.
 * We hook its lifecycle here so the `jarvis/foreground_app` channel is available
 * inside the monitoring isolate — without it, the background loop could never
 * read the foreground app.
 */
class JarvisApplication : Application() {
    private val taskLifecycleListener =
        object : FlutterForegroundTaskLifecycleListener {
            override fun onEngineCreate(flutterEngine: FlutterEngine?) {
                flutterEngine?.let {
                    ForegroundAppChannel.register(it, applicationContext)
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
