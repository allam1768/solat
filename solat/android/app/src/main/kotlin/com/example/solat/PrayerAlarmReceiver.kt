package com.example.solat

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.core.content.ContextCompat

class PrayerAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "onReceive action=$action")

        when (action) {
            ACTION_PRAYER_ALARM -> {
                // Start foreground service untuk tampilkan overlay
                val serviceIntent = Intent(context, PrayerOverlayService::class.java).apply {
                    putExtras(intent.extras ?: return)
                }
                ContextCompat.startForegroundService(context, serviceIntent)
            }

            ACTION_SNOOZE -> {
                val requestCode = intent.getIntExtra(EXTRA_REQUEST_CODE, -1)
                val prayerName = intent.getStringExtra(EXTRA_PRAYER_NAME) ?: "Unknown"
                val attemptCount = intent.getIntExtra(EXTRA_ATTEMPT_COUNT, 0)

                if (requestCode != -1) {
                    NativeOverlayScheduler.scheduleSnooze(context, requestCode, prayerName, attemptCount + 1)
                }
            }

            ACTION_DONE -> {
                val requestCode = intent.getIntExtra(EXTRA_REQUEST_CODE, -1)
                if (requestCode != -1) {
                    // User menandai "sudah sholat" -> reschedule untuk besok di jam yang sama
                    NativeOverlayScheduler.markPrayerDoneAndRescheduleTomorrow(context, requestCode)
                }
            }
        }
    }

    companion object {
        private const val TAG = "PrayerAlarmReceiver"

        const val ACTION_PRAYER_ALARM = "com.example.solat.ACTION_PRAYER_ALARM"
        const val ACTION_SNOOZE = "com.example.solat.ACTION_SNOOZE"
        const val ACTION_DONE = "com.example.solat.ACTION_DONE"

        const val EXTRA_PRAYER_NAME = "extra_prayer_name"
        const val EXTRA_MESSAGE = "extra_message"
        const val EXTRA_NEXT_PRAYER_NAME = "extra_next_prayer_name"
        const val EXTRA_NEXT_PRAYER_TIME = "extra_next_prayer_time"
        const val EXTRA_REQUEST_CODE = "extra_request_code"
        const val EXTRA_IS_SNOOZE = "extra_is_snooze"
        const val EXTRA_BASE_TIME = "extra_base_time"
        const val EXTRA_ATTEMPT_COUNT = "extra_attempt_count"
    }
}