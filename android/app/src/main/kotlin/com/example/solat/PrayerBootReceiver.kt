package com.example.solat

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receiver untuk restore alarm overlay setelah device reboot.
 * Tujuannya: overlay tetap keulang walau aplikasi tidak dibuka.
 */
class PrayerBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "onReceive action=$action")

        if (Intent.ACTION_BOOT_COMPLETED == action || ACTION_QUICKBOOT_POWERON == action) {
            NativeOverlayScheduler.restoreAllSchedulesAfterBoot(context)
        }
    }

    companion object {
        private const val TAG = "PrayerBootReceiver"
        private const val ACTION_QUICKBOOT_POWERON = "android.intent.action.QUICKBOOT_POWERON"
    }
}

