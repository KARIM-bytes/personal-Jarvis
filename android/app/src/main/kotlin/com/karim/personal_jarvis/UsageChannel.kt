package com.karim.personal_jarvis

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

/**
 * Native side of the `jarvis/usage` channel — the app's window onto the phone's
 * own aggregated usage data (the same numbers Digital Wellbeing shows).
 *
 * Registered on both the UI engine ([MainActivity]) and the background-task
 * engine ([JarvisApplication]) so the periodic goal check can read usage.
 */
object UsageChannel {
    private const val CHANNEL = "jarvis/usage"

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
                    "getUsageToday" -> result.success(getUsageToday(appContext))
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

    /**
     * Total foreground time per app since local midnight, as a list of
     * { packageName, label, totalTimeMs }.
     */
    private fun getUsageToday(context: Context): List<Map<String, Any>> {
        if (!hasUsageAccess(context)) return emptyList()

        val usm =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val begin = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

        val aggregated = usm.queryAndAggregateUsageStats(begin, end)
        val pm = context.packageManager
        val result = ArrayList<Map<String, Any>>()

        for ((pkg, stats) in aggregated) {
            val total = stats.totalTimeInForeground
            if (total <= 0L) continue
            val label = try {
                pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
            } catch (_: Exception) {
                pkg
            }
            result.add(
                mapOf(
                    "packageName" to pkg,
                    "label" to label,
                    "totalTimeMs" to total,
                ),
            )
        }
        return result
    }
}
