package com.karim.personal_jarvis

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Native side of the `jarvis/foreground_app` method channel.
 *
 * Registered on both the UI FlutterEngine (via [MainActivity]) and the
 * background-service FlutterEngine (via [JarvisApplication]) so the monitoring
 * isolate can query the foreground app. Kept as a process-wide singleton so the
 * last-known foreground package survives across the frequent polling calls,
 * which makes detection robust even when an app stays in front longer than the
 * UsageStats query window.
 */
object ForegroundAppChannel {
    private const val CHANNEL = "jarvis/foreground_app"

    private var lastPackage: String? = null
    private var lastQueryTime: Long = 0

    fun register(engine: FlutterEngine, context: Context) {
        val appContext = context.applicationContext
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsageAccess" -> result.success(hasUsageAccess(appContext))
                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings(appContext)
                        result.success(null)
                    }
                    "getForegroundApp" -> result.success(getForegroundApp(appContext))
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageAccess(context: Context): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName,
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageAccessSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun getForegroundApp(context: Context): String? {
        if (!hasUsageAccess(context)) return null
        val usm =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        // First call looks back a minute; later calls only read new events.
        val begin = if (lastQueryTime == 0L) now - 60_000 else lastQueryTime - 1_000
        val events = usm.queryEvents(begin, now)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastPackage = event.packageName
            }
        }
        lastQueryTime = now
        return lastPackage
    }
}
