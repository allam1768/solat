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

    // SharedPreferences keys untuk persist jadwal overlay (agar survive reboot & bisa reschedule besok)
    private const val KEY_SCHED_PREFIX = "schedule_"
    private const val KEY_SCHED_HOUR_SUFFIX = "_hour"
    private const val KEY_SCHED_MIN_SUFFIX = "_min"
    private const val KEY_SCHED_PRAYER_SUFFIX = "_prayer"
    private const val KEY_SCHED_MSG_SUFFIX = "_msg"
    private const val KEY_SCHED_NEXT_NAME_SUFFIX = "_next_name"
    private const val KEY_SCHED_NEXT_TIME_SUFFIX = "_next_time"
    private const val KEY_SCHED_BASE_TIME_SUFFIX = "_base_time"

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
                    message = "Fajr time will end in 30 minutes!\nPlease pray Fajr soon.",
                    nextPrayerName = "Sunrise",
                    nextPrayerTime = sunrise
                )

                // Dzuhur: 30 menit sebelum Ashar
                scheduleSingleOverlay(
                    context = context,
                    requestCode = REQ_DZUHUR,
                    baseTime = asr,
                    offsetMinutes = -30,
                    prayerName = "Dzuhur",
                    message = "Dhuhr time will end in 30 minutes!\nPlease pray Dhuhr soon.",
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
                    message = "Asr time will end in 30 minutes!\nPlease pray Asr soon.",
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
                    message = "Maghrib time will end in 30 minutes!\nPlease pray Maghrib soon.",
                    nextPrayerName = "Isya",
                    nextPrayerTime = isha
                )

                // Isya: 60 menit setelah Isya
                scheduleSingleOverlay(
                    context = context,
                    requestCode = REQ_ISYA,
                    baseTime = isha,
                    offsetMinutes = 60,
                    prayerName = "Isya",
                    message = "It has been 60 minutes since Isha started.\nPlease pray Isha soon.",
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
        scheduleOverlayAt(
            context = context,
            requestCode = requestCode,
            triggerAtMillis = cal.timeInMillis,
            prayerName = prayerName,
            message = message,
            nextPrayerName = nextPrayerName,
            nextPrayerTime = nextPrayerTime,
            baseTime = baseTime,
            attemptCount = 0,
        )

        // Persist supaya:
        // - bisa reschedule besok saat user klik "I've prayed"
        // - bisa restore setelah reboot meskipun app tidak dibuka
        persistSchedule(
            context = context,
            requestCode = requestCode,
            hour = cal.get(Calendar.HOUR_OF_DAY),
            minute = cal.get(Calendar.MINUTE),
            prayerName = prayerName,
            message = message,
            nextPrayerName = nextPrayerName,
            nextPrayerTime = nextPrayerTime,
            baseTime = baseTime,
        )

        Log.d(TAG, "Scheduled $prayerName overlay at ${cal.time} (persisted)")
    }

    fun scheduleSnooze(context: Context, requestCode: Int, prayerName: String, currentAttempt: Int) {
        // Max 2 snooze (attempt 0, 1, 2)
        if (currentAttempt > 2) {
            Log.d(TAG, "Max snooze reached for $prayerName")
            return
        }

        // Save attempt count
        saveAttemptCount(context, requestCode, currentAttempt)

        val snoozeMinutes = if (currentAttempt == 1) 10 else 5

        val cal = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            add(Calendar.MINUTE, snoozeMinutes)
        }

        // Ambil data yang tersimpan untuk melengkapi intent snooze
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val message = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MSG_SUFFIX", "It's time") ?: "It's time"
        val nextName = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_NAME_SUFFIX", "") ?: ""
        val nextTime = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_TIME_SUFFIX", "") ?: ""
        val baseTime = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_BASE_TIME_SUFFIX", "") ?: ""

        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_PRAYER_ALARM
            putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
            putExtra(PrayerAlarmReceiver.EXTRA_MESSAGE, message)
            putExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_NAME, nextName)
            putExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_TIME, nextTime)
            putExtra(PrayerAlarmReceiver.EXTRA_BASE_TIME, baseTime)
            putExtra(PrayerAlarmReceiver.EXTRA_IS_SNOOZE, true)
            putExtra(PrayerAlarmReceiver.EXTRA_REQUEST_CODE, requestCode)
            putExtra(PrayerAlarmReceiver.EXTRA_ATTEMPT_COUNT, currentAttempt)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode + 1000, // Bedain ID snooze pakai +1000 biar gak menghapus alarm besok
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

    fun cancelPrayer(context: Context, requestCode: Int, clearPersisted: Boolean = true) {
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
        val snoozePendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode + 1000,
            intent,
            flags
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent)
        alarmManager.cancel(snoozePendingIntent) // Pastikan snooze juga kehapus


        // Reset attempt count
        resetAttemptCount(context, requestCode)

        if (clearPersisted) {
            clearPersistedSchedule(context, requestCode)
        }

        Log.d(TAG, "Cancelled prayer alarm rc=$requestCode")
    }

    fun cancelAll(context: Context) {
        cancelPrayer(context, REQ_SUBUH, clearPersisted = true)
        cancelPrayer(context, REQ_DZUHUR, clearPersisted = true)
        cancelPrayer(context, REQ_ASHAR, clearPersisted = true)
        cancelPrayer(context, REQ_MAGHRIB, clearPersisted = true)
        cancelPrayer(context, REQ_ISYA, clearPersisted = true)
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

    /**
     * Dipanggil saat user klik "I've prayed" -> jadwalkan overlay yang sama untuk BESOK di jam yang sama.
     * (Tanggal/bulan/tahun maju +1 hari, jam/menit tetap)
     */
    fun markPrayerDoneAndRescheduleTomorrow(context: Context, requestCode: Int) {
        // Batalkan alarm yang sedang aktif, tapi JANGAN hapus jadwal tersimpan.
        cancelPrayer(context, requestCode, clearPersisted = false)
        rescheduleTomorrowFromPersisted(context, requestCode)
    }

    /**
     * ✅ FUNGSI BARU: Schedule besok TANPA cancel alarm hari ini
     * Digunakan di overlay pertama untuk memastikan besok pasti ada alarm,
     * tapi tetap mempertahankan alarm hari ini agar bisa snooze 3x
     */
    fun scheduleTomorrowWithoutCancellingToday(context: Context, requestCode: Int) {
        // TIDAK memanggil cancelPrayer(), langsung schedule besok saja
        rescheduleTomorrowFromPersisted(context, requestCode)
    }

    /**
     * Restore semua jadwal overlay dari SharedPreferences (mis. setelah reboot).
     */
    fun restoreAllSchedulesAfterBoot(context: Context) {
        val requestCodes = listOf(REQ_SUBUH, REQ_DZUHUR, REQ_ASHAR, REQ_MAGHRIB, REQ_ISYA)
        requestCodes.forEach { rc ->
            restoreAndRescheduleSingle(context, rc)
        }
    }

    private fun restoreAndRescheduleSingle(context: Context, requestCode: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hourKey = "$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_HOUR_SUFFIX"
        val minKey = "$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MIN_SUFFIX"
        if (!prefs.contains(hourKey) || !prefs.contains(minKey)) return

        val hour = prefs.getInt(hourKey, -1)
        val minute = prefs.getInt(minKey, -1)
        if (hour !in 0..23 || minute !in 0..59) return

        val prayerName = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_PRAYER_SUFFIX", "Prayer") ?: "Prayer"
        val message = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MSG_SUFFIX", "It's time") ?: "It's time"
        val nextPrayerName = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_NAME_SUFFIX", "") ?: ""
        val nextPrayerTime = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_TIME_SUFFIX", "") ?: ""
        val baseTime = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_BASE_TIME_SUFFIX", "") ?: ""

        // Schedule untuk waktu terdekat: hari ini jam:menit, kalau sudah lewat -> besok
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= now) add(Calendar.DAY_OF_YEAR, 1)
        }

        scheduleOverlayAt(
            context = context,
            requestCode = requestCode,
            triggerAtMillis = cal.timeInMillis,
            prayerName = prayerName,
            message = message,
            nextPrayerName = nextPrayerName,
            nextPrayerTime = nextPrayerTime,
            baseTime = baseTime,
            attemptCount = 0,
        )

        Log.d(TAG, "Restored overlay rc=$requestCode at ${cal.time}")
    }

    private fun rescheduleTomorrowFromPersisted(context: Context, requestCode: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hour = prefs.getInt("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_HOUR_SUFFIX", -1)
        val minute = prefs.getInt("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MIN_SUFFIX", -1)
        if (hour !in 0..23 || minute !in 0..59) {
            Log.w(TAG, "No persisted schedule for rc=$requestCode; cannot reschedule tomorrow")
            return
        }

        val prayerName = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_PRAYER_SUFFIX", "Prayer") ?: "Prayer"
        val message = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MSG_SUFFIX", "It's time") ?: "It's time"
        val nextPrayerName = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_NAME_SUFFIX", "") ?: ""
        val nextPrayerTime = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_TIME_SUFFIX", "") ?: ""
        val baseTime = prefs.getString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_BASE_TIME_SUFFIX", "") ?: ""

        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            timeInMillis = now
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        scheduleOverlayAt(
            context = context,
            requestCode = requestCode,
            triggerAtMillis = cal.timeInMillis,
            prayerName = prayerName,
            message = message,
            nextPrayerName = nextPrayerName,
            nextPrayerTime = nextPrayerTime,
            baseTime = baseTime,
            attemptCount = 0,
        )

        Log.d(TAG, "Rescheduled tomorrow rc=$requestCode at ${cal.time}")
    }

    private fun scheduleOverlayAt(
        context: Context,
        requestCode: Int,
        triggerAtMillis: Long,
        prayerName: String,
        message: String,
        nextPrayerName: String,
        nextPrayerTime: String,
        baseTime: String,
        attemptCount: Int,
    ) {
        val intent = Intent(context, PrayerAlarmReceiver::class.java).apply {
            action = PrayerAlarmReceiver.ACTION_PRAYER_ALARM
            putExtra(PrayerAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
            putExtra(PrayerAlarmReceiver.EXTRA_MESSAGE, message)
            putExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_NAME, nextPrayerName)
            putExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_TIME, nextPrayerTime)
            putExtra(PrayerAlarmReceiver.EXTRA_BASE_TIME, baseTime)
            putExtra(PrayerAlarmReceiver.EXTRA_REQUEST_CODE, requestCode)
            putExtra(PrayerAlarmReceiver.EXTRA_ATTEMPT_COUNT, attemptCount)
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
    }

    private fun persistSchedule(
        context: Context,
        requestCode: Int,
        hour: Int,
        minute: Int,
        prayerName: String,
        message: String,
        nextPrayerName: String,
        nextPrayerTime: String,
        baseTime: String,
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putInt("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_HOUR_SUFFIX", hour)
            .putInt("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MIN_SUFFIX", minute)
            .putString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_PRAYER_SUFFIX", prayerName)
            .putString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MSG_SUFFIX", message)
            .putString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_NAME_SUFFIX", nextPrayerName)
            .putString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_TIME_SUFFIX", nextPrayerTime)
            .putString("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_BASE_TIME_SUFFIX", baseTime)
            .apply()
    }

    private fun clearPersistedSchedule(context: Context, requestCode: Int) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .remove("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_HOUR_SUFFIX")
            .remove("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MIN_SUFFIX")
            .remove("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_PRAYER_SUFFIX")
            .remove("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_MSG_SUFFIX")
            .remove("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_NAME_SUFFIX")
            .remove("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_NEXT_TIME_SUFFIX")
            .remove("$KEY_SCHED_PREFIX$requestCode$KEY_SCHED_BASE_TIME_SUFFIX")
            .apply()
    }
}