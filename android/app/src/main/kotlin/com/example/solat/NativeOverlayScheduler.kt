package com.example.solat

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar

object NativeOverlayScheduler {

    private const val TAG = "NativeOverlayScheduler"

    // Request code per prayer
    private const val REQ_SUBUH = 101
    private const val REQ_DZUHUR = 102
    private const val REQ_ASHAR = 103
    private const val REQ_MAGHRIB = 104
    private const val REQ_ISYA = 105

    // SharedPreferences key untuk tracking attempt count
    private const val PREFS_NAME = "prayer_overlay_prefs"
    private const val KEY_ATTEMPT_PREFIX = "attempt_count_"

    fun schedulePrayerOverlays(context: Context, times: Map<String, String?>) {
        try {
            cancelAll(context)
            resetAllAttemptCounts(context)

            val sunrise = times["sunrise"]
            val dhuhr = times["dhuhr"]
            val asr = times["asr"]
            val maghrib = times["maghrib"]
            val isha = times["isha"]
            val fajr = times["fajr"]

            if (sunrise != null && dhuhr != null && asr != null && maghrib != null && isha != null && fajr != null) {
                // Subuh: 30 menit sebelum Sunrise
                scheduleSingleOverlay(
                    context = context,
                    requestCode = REQ_SUBUH,
                    baseTime = sunrise,
                    offsetMinutes = -30,
                    prayerName = "Subuh",
                    message = "Waktu Subuh akan berakhir dalam 30 menit!\nAyo segera sholat Subuh.",
                    nextPrayerName = "Dzuhur",
                    nextPrayerTime = dhuhr
                )

                // Dzuhur: 30 menit sebelum Ashar
                scheduleSingleOverlay(
                    context = context,
                    requestCode = REQ_DZUHUR,
                    baseTime = asr,
                    offsetMinutes = -30,
                    prayerName = "Dzuhur",
                    message = "Waktu Dzuhur akan berakhir dalam 30 menit!\nAyo segera sholat Dzuhur.",
                    nextPrayerName = "Ashar",
                    nextPrayerTime = asr
                )

                // Ashar: 30 menit sebelum Maghrib
                scheduleSingleOverlay(
                    context = context,
                    requestCode = REQ_ASHAR,
                    baseTime = maghrib,
                    offsetMinutes = -30,
                    prayerName = "Ashar",
                    message = "Waktu Ashar akan berakhir dalam 30 menit!\nAyo segera sholat Ashar.",
                    nextPrayerName = "Maghrib",
                    nextPrayerTime = maghrib
                )

                // Maghrib: 30 menit sebelum Isya
                scheduleSingleOverlay(
                    context = context,
                    requestCode = REQ_MAGHRIB,
                    baseTime = isha,
                    offsetMinutes = -30,
                    prayerName = "Maghrib",
                    message = "Waktu Maghrib akan berakhir dalam 30 menit!\nAyo segera sholat Maghrib.",
                    nextPrayerName = "Isya",
                    nextPrayerTime = isha
                )

                // Isya: 30 menit setelah Isya
                scheduleSingleOverlay(
                    context = context,
                    requestCode = REQ_ISYA,
                    baseTime = isha,
                    offsetMinutes = 30,
                    prayerName = "Isya",
                    message = "Sudah 30 menit sejak masuk waktu Isya!\nAyo segera sholat Isya.",
                    nextPrayerName = "Subuh",
                    nextPrayerTime = fajr
                )
            } else {
                Log.w(TAG, "Incomplete prayer times, skip native overlay schedule")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling native overlays", e)
        }
    }

    private fun scheduleSingleOverlay(
        context: Context,
        requestCode: Int,
        baseTime: String,
        offsetMinutes: Int,
        prayerName: String,
        message: String,
        nextPrayerName: String,
        nextPrayerTime: String
    ) {
        val hm = baseTime.split(":")
        if (hm.size != 2) {
            Log.w(TAG, "Invalid time format for $prayerName: $baseTime")
            return
        }

        val hour = hm[0].toIntOrNull() ?: return
        val minute = hm[1].toIntOrNull() ?: return

        val cal = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            add(Calendar.MINUTE, offsetMinutes)
        }

        // Kalau sudah lewat, geser ke hari berikutnya
        if (cal.timeInMillis <= System.currentTimeMillis()) {
            cal.add(Calendar.DAY_OF_YEAR, 1)
        }

        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_PRAYER_ALARM
            putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
            putExtra(PrayerAlarmReceiver.EXTRA_MESSAGE, message)
            putExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_NAME, nextPrayerName)
            putExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_TIME, nextPrayerTime)
            putExtra(PrayerAlarmReceiver.EXTRA_REQUEST_CODE, requestCode)
            putExtra(PrayerAlarmReceiver.EXTRA_ATTEMPT_COUNT, 0)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            flags
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                cal.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                cal.timeInMillis,
                pendingIntent
            )
        }

        Log.d(TAG, "Scheduled $prayerName overlay at ${cal.time}")
    }

    fun scheduleSnooze(context: Context, requestCode: Int, prayerName: String, currentAttempt: Int) {
        // Max 2 snooze (attempt 0, 1, 2)
        if (currentAttempt >= 2) {
            Log.d(TAG, "Max snooze reached for $prayerName")
            return
        }

        // Save attempt count
        saveAttemptCount(context, requestCode, currentAttempt)

        // Snooze +5 menit
        val cal = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            add(Calendar.MINUTE, 5)
        }

        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_PRAYER_ALARM
            putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
            putExtra(PrayerAlarmReceiver.EXTRA_IS_SNOOZE, true)
            putExtra(PrayerAlarmReceiver.EXTRA_REQUEST_CODE, requestCode)
            putExtra(PrayerAlarmReceiver.EXTRA_ATTEMPT_COUNT, currentAttempt)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            flags
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                cal.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                cal.timeInMillis,
                pendingIntent
            )
        }

        Log.d(TAG, "Snooze $prayerName (attempt $currentAttempt) to ${cal.time}")
    }

    fun cancelPrayer(context: Context, requestCode: Int) {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_PRAYER_ALARM
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            flags
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)

        // Reset attempt count
        resetAttemptCount(context, requestCode)

        Log.d(TAG, "Cancelled prayer alarm rc=$requestCode")
    }

    fun cancelAll(context: Context) {
        cancelPrayer(context, REQ_SUBUH)
        cancelPrayer(context, REQ_DZUHUR)
        cancelPrayer(context, REQ_ASHAR)
        cancelPrayer(context, REQ_MAGHRIB)
        cancelPrayer(context, REQ_ISYA)
    }

    // Helper functions untuk attempt count
    private fun saveAttemptCount(context: Context, requestCode: Int, count: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putInt("$KEY_ATTEMPT_PREFIX$requestCode", count).apply()
    }

    private fun getAttemptCount(context: Context, requestCode: Int): Int {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt("$KEY_ATTEMPT_PREFIX$requestCode", 0)
    }

    private fun resetAttemptCount(context: Context, requestCode: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().remove("$KEY_ATTEMPT_PREFIX$requestCode").apply()
    }

    private fun resetAllAttemptCounts(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().clear().apply()
    }
}