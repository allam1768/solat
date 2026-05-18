package com.example.solat

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar

object NativeBasicNotificationScheduler {

    private const val TAG = "NativeBasicNotifSched"
    private const val PREFS_NAME = "basic_notification_prefs"
    private const val KEY_ACTIVE_IDS = "active_ids"
    private const val KEY_PREFIX = "notif_"

    fun scheduleNotifications(context: Context, schedules: List<Map<String, Any>>) {
        try {
            cancelAll(context)
            
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val editor = prefs.edit()
            editor.clear() // Clear old schedules

            val idList = mutableListOf<Int>()

            for (item in schedules) {
                val id = (item["id"] as? Number)?.toInt() ?: continue
                val title = item["title"] as? String ?: continue
                val body = item["body"] as? String ?: continue
                val time = item["time"] as? String ?: continue

                scheduleSingle(context, id, title, body, time)
                
                // Persist
                idList.add(id)
                editor.putString("${KEY_PREFIX}${id}_title", title)
                editor.putString("${KEY_PREFIX}${id}_body", body)
                editor.putString("${KEY_PREFIX}${id}_time", time)
            }

            editor.putString(KEY_ACTIVE_IDS, idList.joinToString(","))
            editor.apply()
            
            Log.d(TAG, "Scheduled and persisted ${idList.size} basic notifications")
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling basic notifications", e)
        }
    }

    private fun scheduleSingle(context: Context, id: Int, title: String, body: String, time: String) {
        val hm = time.split(":")
        if (hm.size != 2) return

        val hour = hm[0].toIntOrNull() ?: return
        val minute = hm[1].toIntOrNull() ?: return

        val cal = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        if (cal.timeInMillis <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }

        // Ensure Friday preparation reminders (IDs 204 and 205) are strictly scheduled for Fridays.
        if (id == 204 || id == 205) {
            while (cal.get(Calendar.DAY_OF_WEEK) != Calendar.FRIDAY) {
                cal.add(Calendar.DAY_OF_YEAR, 1)
            }
        }

        scheduleAlarmAt(context, id, title, body, cal.timeInMillis)
    }

    private fun scheduleAlarmAt(context: Context, id: Int, title: String, body: String, triggerAtMillis: Long) {
        val intent = Intent(context, BasicNotificationReceiver::class.java).apply {
            action = BasicNotificationReceiver.ACTION_SHOW_NOTIFICATION
            putExtra(BasicNotificationReceiver.EXTRA_ID, id)
            putExtra(BasicNotificationReceiver.EXTRA_TITLE, title)
            putExtra(BasicNotificationReceiver.EXTRA_BODY, body)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            flags
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent
            )
        }
        
        Log.d(TAG, "Scheduled alarm id=$id for $title at triggerAtMillis=$triggerAtMillis")
    }

    fun cancelAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val activeIdsStr = prefs.getString(KEY_ACTIVE_IDS, "") ?: ""
        
        if (activeIdsStr.isNotEmpty()) {
            val ids = activeIdsStr.split(",").mapNotNull { it.toIntOrNull() }
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            for (id in ids) {
                val intent = Intent(context, BasicNotificationReceiver::class.java).apply {
                    action = BasicNotificationReceiver.ACTION_SHOW_NOTIFICATION
                }
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                        (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                val pendingIntent = PendingIntent.getBroadcast(context, id, intent, flags)
                
                alarmManager.cancel(pendingIntent)
            }
        }
        
        prefs.edit().clear().apply()
        Log.d(TAG, "Cancelled all basic native notifications")
    }

    fun restoreAllSchedulesAfterBoot(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val activeIdsStr = prefs.getString(KEY_ACTIVE_IDS, "") ?: ""
        
        if (activeIdsStr.isNotEmpty()) {
            val ids = activeIdsStr.split(",").mapNotNull { it.toIntOrNull() }
            
            for (id in ids) {
                val title = prefs.getString("${KEY_PREFIX}${id}_title", "") ?: ""
                val body = prefs.getString("${KEY_PREFIX}${id}_body", "") ?: ""
                val time = prefs.getString("${KEY_PREFIX}${id}_time", "") ?: ""
                
                if (title.isNotEmpty() && time.isNotEmpty()) {
                    scheduleSingle(context, id, title, body, time)
                }
            }
            Log.d(TAG, "Restored ${ids.size} basic notifications after boot")
        }
    }
    
    fun rescheduleForTomorrow(context: Context, id: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val title = prefs.getString("${KEY_PREFIX}${id}_title", "") ?: ""
        val body = prefs.getString("${KEY_PREFIX}${id}_body", "") ?: ""
        val time = prefs.getString("${KEY_PREFIX}${id}_time", "") ?: ""
        
        if (title.isNotEmpty() && time.isNotEmpty()) {
            scheduleSingle(context, id, title, body, time)
            Log.d(TAG, "Rescheduled basic notification id=$id for tomorrow")
        }
    }
}
