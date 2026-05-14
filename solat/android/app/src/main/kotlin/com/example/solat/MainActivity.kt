package com.example.solat

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val OVERLAY_CHANNEL = "solat/native_overlay"
    private val NOTIFICATION_CHANNEL = "solat/native_notification"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OVERLAY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedulePrayerOverlays" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("INVALID_ARGS", "Arguments must be a map", null)
                        return@setMethodCallHandler
                    }

                    @Suppress("UNCHECKED_CAST")
                    val times = args.mapKeys { it.key.toString() } as Map<String, String?>

                    NativeOverlayScheduler.schedulePrayerOverlays(this, times)
                    result.success(null)
                }

                "cancelPrayerOverlays" -> {
                    NativeOverlayScheduler.cancelAll(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleBasicNotifications" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("INVALID_ARGS", "Arguments must be a map", null)
                        return@setMethodCallHandler
                    }

                    @Suppress("UNCHECKED_CAST")
                    val schedules = args["schedules"] as? List<Map<String, Any>>
                    if (schedules != null) {
                        NativeBasicNotificationScheduler.scheduleNotifications(this, schedules)
                    }
                    result.success(null)
                }

                "cancelBasicNotifications" -> {
                    NativeBasicNotificationScheduler.cancelAll(this)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}