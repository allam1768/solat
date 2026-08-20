package com.putraa.solat

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * ForegroundService yang menampilkan overlay full-screen via WindowManager.
 * Mendukung max 2x snooze (total 3 overlay), dengan desain berbeda untuk overlay terakhir.
 *
 * Flow:
 * - Overlay 1 (attempt 0):
 *   ✅ AUTO-SCHEDULE BESOK (tanpa cancel alarm hari ini!)
 *   → Auto-snooze 10 menit jika tidak ada interaksi
 * - Overlay 2 (attempt 1): Auto-snooze 5 menit jika tidak ada interaksi
 * - Overlay 3 (attempt 2): Auto-snooze "sampai waktu sholat selanjutnya" (Dismiss)
 *
 * PASTI-PASTI:
 * - Overlay muncul 3x jika diabaikan (dengan durasi snooze berbeda)
 * - Besok PASTI ada alarm (karena auto-schedule di overlay 1)
 */
class PrayerOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null
    private var autoSnoozeHandler: android.os.Handler? = null
    private var autoSnoozeRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannelIfNeeded()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        autoSnoozeHandler = android.os.Handler(android.os.Looper.getMainLooper())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopSelf()
            return START_NOT_STICKY
        }

        val prayerName = intent.getStringExtra(PrayerAlarmReceiver.EXTRA_PRAYER_NAME) ?: "sholat"
        val message = intent.getStringExtra(PrayerAlarmReceiver.EXTRA_MESSAGE)
            ?: "udah masuk waktu sholat $prayerName"
        val nextPrayerName = intent.getStringExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_NAME) ?: ""
        val nextPrayerTime = intent.getStringExtra(PrayerAlarmReceiver.EXTRA_NEXT_PRAYER_TIME) ?: ""
        val requestCode = intent.getIntExtra(PrayerAlarmReceiver.EXTRA_REQUEST_CODE, -1)
        val attemptCount = intent.getIntExtra(PrayerAlarmReceiver.EXTRA_ATTEMPT_COUNT, 0)
        val baseTime = intent.getStringExtra(PrayerAlarmReceiver.EXTRA_BASE_TIME) ?: ""

        val notification = buildForegroundNotification(prayerName, message)
        startForeground(FOREGROUND_NOTIFICATION_ID, notification)

        showOverlay(
            prayerName = prayerName,
            message = message,
            nextPrayerName = nextPrayerName,
            nextPrayerTime = nextPrayerTime,
            baseTime = baseTime,
            requestCode = requestCode,
            attemptCount = attemptCount
        )

        return START_NOT_STICKY
    }

    // Helper function to convert dp to pixel
    private fun Int.dp(): Int {
        return (this * resources.displayMetrics.density).toInt()
    }

    private fun Float.dp(): Int {
        return (this * resources.displayMetrics.density).toInt()
    }

    private fun showOverlay(
        prayerName: String,
        message: String,
        nextPrayerName: String,
        nextPrayerTime: String,
        baseTime: String,
        requestCode: Int,
        attemptCount: Int
    ) {
        removeOverlay()
        cancelAutoSnooze()

        // ✅ Cek apakah waktu sholat berikutnya/terbit sudah lewat (misal jam Sunrise sudah lewat untuk Subuh)
        if (prayerName != "Isya" && nextPrayerTime.isNotEmpty() && isPastTime(nextPrayerTime)) {
            android.util.Log.d("PrayerOverlayService", "Next prayer time ($nextPrayerTime) has passed for $prayerName. Auto-closing overlay and sending missed notification.")
            showMissedNotification(prayerName)
            stopSelf()
            return
        }

        // ✅ Tambahkan getaran ringan saat overlay muncul
        vibratePhone(attemptCount)

        val ctx = this
        val isLastAttempt = attemptCount >= 2

        // ✅ SOLUSI FINAL: Auto-schedule besok di overlay PERTAMA (attempt 0)
        // TANPA cancel alarm hari ini, jadi overlay tetap bisa muncul 3x
        if (attemptCount == 0 && requestCode != -1) {
            NativeOverlayScheduler.scheduleTomorrowWithoutCancellingToday(ctx, requestCode)
        }

        // Setup auto snooze:
        // Overlay 1 & 2: 2 menit on-screen (timeout) -> snooze 10m/5m
        // Overlay 3: Stay UNTIL next prayer time
        scheduleAutoSnooze(requestCode, prayerName, attemptCount, nextPrayerTime)

        // ========================================
        // ROOT CONTAINER
        // ========================================
        val root = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#99000000")) // 0.6 opacity
            gravity = Gravity.CENTER
            setPadding(20.dp(), 0, 20.dp(), 0) // horizontal 20dp
        }

        // ========================================
        // CARD CONTAINER
        // ========================================
        val screenWidth = resources.displayMetrics.widthPixels
        val targetWidth = (screenWidth * 0.86).toInt().coerceIn(280.dp(), 380.dp())

        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24.dp(), 28.dp(), 24.dp(), 28.dp()) // padding 24dp horizontal, 28dp vertical
            gravity = Gravity.CENTER

            layoutParams = LinearLayout.LayoutParams(
                targetWidth,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )

            // Rounded rectangle dengan border 4dp dan cornerRadius 30dp
            val drawable = android.graphics.drawable.GradientDrawable().apply {
                shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                setColor(Color.WHITE)
                cornerRadius = 30f.dp().toFloat() // 30dp rounded
                setStroke(4.dp(), Color.BLACK) // 4dp border
            }
            background = drawable

            // Shadow effect
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                elevation = 12f.dp().toFloat()
            }
        }

        // ========================================
        // LOGO ICON
        // ========================================
        val iconView = android.widget.ImageView(ctx).apply {
            setImageResource(R.drawable.ic_moon_star)
            setColorFilter(Color.BLACK)
            layoutParams = LinearLayout.LayoutParams(90.dp(), 90.dp())
        }

        // ========================================
        // PRAYER NAME TITLE
        // ========================================
        val titleView = TextView(ctx).apply {
            text = prayerName
            textSize = 28f
            setTextColor(Color.BLACK)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 24.dp(), 0, 12.dp())
        }

        // ========================================
        // MESSAGE TEXT (DYNAMIC)
        // ========================================
        val dynamicMessage = if (baseTime.isNotEmpty()) {
            if (prayerName == "Isya") {
                val diff = getMinutesDifference(baseTime, isPast = true)
                if (diff >= 0) {
                    "udah $diff menit sejak waktu sholat $prayerName dimulai.\nyuk sholat $prayerName sekarang."
                } else message
            } else {
                val diff = getMinutesDifference(baseTime, isPast = false)
                when {
                    diff > 0 -> "waktu $prayerName sisa $diff menit lagi nih.\nsempatin sholat dulu, yuk."
                    diff == 0 -> "waktu $prayerName bentar lagi habis! yuk\nburuan sholat biar nggak kelewat."
                    else -> "waktu $prayerName udah habis!\nyuk sholat $prayerName sekarang."
                }
            }
        } else {
            message
        }

        val messageView = TextView(ctx).apply {
            text = dynamicMessage
            textSize = 14f
            setTextColor(Color.BLACK)
            typeface = Typeface.create(Typeface.DEFAULT, 600, false)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32.dp())
        }

        // ========================================
        // BUTTONS SECTION
        // ========================================
        if (isLastAttempt) {
            // ==========================================
            // ATTEMPT 3 - VERTICAL BUTTONS (CRITICAL)
            // ==========================================

            val buttonsContainer = LinearLayout(ctx).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

            // ✅ "udah solat" BUTTON (Filled Black, Full Width)
            val doneButton = Button(ctx).apply {
                text = "udah solat"
                textSize = 15f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, 12.dp(), 0, 12.dp())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.BLACK)
                    cornerRadius = 30f.dp().toFloat()
                }

                isAllCaps = false
                stateListAnimator = null

                setOnClickListener {
                    removeOverlay()
                    stopSelf()
                }
            }

            // ✅ Spacing 10dp
            val spacer1 = android.view.View(ctx).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    10.dp()
                )
            }

            // ✅ "OTW" BUTTON (Outlined Black, Full Width)
            val onMyWayButton = Button(ctx).apply {
                text = "OTW"
                textSize = 15f
                setTextColor(Color.BLACK)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, 12.dp(), 0, 12.dp())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.WHITE)
                    cornerRadius = 30f.dp().toFloat()
                    setStroke(3.dp(), Color.BLACK)
                }

                isAllCaps = false
                stateListAnimator = null

                setOnClickListener {
                    removeOverlay()
                    stopSelf()
                }
            }

            buttonsContainer.addView(doneButton)
            buttonsContainer.addView(spacer1)
            buttonsContainer.addView(onMyWayButton)

            card.addView(iconView)
            card.addView(titleView)
            card.addView(messageView)
            card.addView(buttonsContainer)

        } else {
            // ==========================================
            // ATTEMPT 1 & 2 - HORIZONTAL BUTTONS
            // ==========================================

            val buttonsLayout = LinearLayout(ctx).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

            // ✅ "udah solat" BUTTON (Filled Black)
            val doneButton = Button(ctx).apply {
                text = "udah solat"
                textSize = 15f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, 12.dp(), 0, 12.dp())
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply {
                    setMargins(0, 0, 10.dp(), 0)
                }

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.BLACK)
                    cornerRadius = 30f.dp().toFloat()
                }

                isAllCaps = false
                stateListAnimator = null

                setOnClickListener {
                    removeOverlay()
                    stopSelf()
                }
            }

            // ✅ "nanti" BUTTON (Outlined Black)
            val laterButton = Button(ctx).apply {
                text = "nanti"
                textSize = 15f
                setTextColor(Color.BLACK)
                typeface = Typeface.DEFAULT_BOLD
                setPadding(0, 12.dp(), 0, 12.dp())
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                )

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.WHITE)
                    cornerRadius = 30f.dp().toFloat()
                    setStroke(3.dp(), Color.BLACK)
                }

                isAllCaps = false
                stateListAnimator = null

                setOnClickListener {
                    cancelAutoSnooze()
                    if (requestCode != -1) {
                        NativeOverlayScheduler.scheduleSnooze(ctx, requestCode, prayerName, attemptCount + 1)
                    }
                    removeOverlay()
                    stopSelf()
                }
            }

            buttonsLayout.addView(doneButton)
            buttonsLayout.addView(laterButton)

            card.addView(iconView)
            card.addView(titleView)
            card.addView(messageView)
            card.addView(buttonsLayout)
        }

        // ========================================
        // ADD CARD TO ROOT
        // ========================================
        root.addView(card)

        // ========================================
        // WINDOW LAYOUT PARAMS
        // ========================================
        val layoutParams = WindowManager.LayoutParams().apply {
            width = WindowManager.LayoutParams.MATCH_PARENT
            height = WindowManager.LayoutParams.MATCH_PARENT
            gravity = Gravity.CENTER

            type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            flags = WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_INSET_DECOR or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON

            format = android.graphics.PixelFormat.TRANSLUCENT
        }

        try {
            windowManager?.addView(root, layoutParams)
            overlayView = root
        } catch (e: Exception) {
            android.util.Log.e("PrayerOverlayService", "Failed to add overlay view (permission denied or bad token)", e)
            showFallbackNotification(prayerName, message)
            stopSelf()
        }
    }

    private fun removeOverlay() {
        cancelAutoSnooze()
        overlayView?.let { view ->
            windowManager?.removeView(view)
        }
        overlayView = null
    }

    private fun scheduleAutoSnooze(requestCode: Int, prayerName: String, attemptCount: Int, nextPrayerTime: String) {
        val isLastAttempt = attemptCount >= 2
        
        autoSnoozeRunnable = Runnable {
            if (isLastAttempt) {
                // Overlay 3: User mengabaikan sampai waktu sholat berikutnya masuk (kemungkinan ketiduran/sibuk)
                showMissedNotification(prayerName)
                removeOverlay()
                stopSelf()
            } else {
                // Overlay 1 & 2: Jadwalkan snooze (10m / 5m)
                if (requestCode != -1) {
                    NativeOverlayScheduler.scheduleSnooze(this, requestCode, prayerName, attemptCount + 1)
                }
                removeOverlay()
                stopSelf()
            }
        }

        val delayMillis = if (isLastAttempt) {
            if (prayerName == "Isya") {
                // Khusus Isya: Hardcode 10 menit standby di layar
                600000L 
            } else {
                // Sholat lain: Tunggu sampai waktu sholat berikutnya (auto-close saat sholat selanjutnya masuk)
                getMillisUntil(nextPrayerTime).let { 
                    if (it >= 0) it else 3600000 // Fallback 1 jam kalau gagal parse
                }
            }
        } else {
            // Overlay 1 & 2: Tunggu 2 menit di layar sebelum auto-snooze
            120000L
        }

        autoSnoozeHandler?.postDelayed(autoSnoozeRunnable!!, delayMillis)
    }

    private fun getMinutesDifference(timeStr: String, isPast: Boolean): Int {
        if (timeStr.isEmpty()) return -1
        return try {
            val hm = timeStr.split(":")
            if (hm.size != 2) return -1
            val h = hm[0].toInt()
            val m = hm[1].toInt()
            
            val now = java.util.Calendar.getInstance()
            val target = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, h)
                set(java.util.Calendar.MINUTE, m)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            
            if (isPast) {
                // Counting minutes since start. If target is in the future, it was likely yesterday (e.g. 23:00 yesterday vs 01:00 today)
                if (target.after(now)) {
                    target.add(java.util.Calendar.DAY_OF_YEAR, -1)
                }
            } else {
                // Counting minutes until end. If target is in the past, it's likely tomorrow (e.g. 04:30 tomorrow vs 23:00 today)
                if (target.before(now)) {
                    target.add(java.util.Calendar.DAY_OF_YEAR, 1)
                }
            }
            
            val diffMillis = if (isPast) {
                now.timeInMillis - target.timeInMillis
            } else {
                target.timeInMillis - now.timeInMillis
            }
            
            (diffMillis / 60000).toInt()
        } catch (e: Exception) {
            -1
        }
    }

    private fun isPastTime(timeStr: String): Boolean {
        if (timeStr.isEmpty()) return false
        return try {
            val hm = timeStr.split(":")
            if (hm.size != 2) return false
            val h = hm[0].toInt()
            val m = hm[1].toInt()

            val now = java.util.Calendar.getInstance()
            val target = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, h)
                set(java.util.Calendar.MINUTE, m)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            now.timeInMillis >= target.timeInMillis
        } catch (e: Exception) {
            false
        }
    }

    private fun getMillisUntil(timeStr: String): Long {
        if (timeStr.isEmpty()) return -1
        return try {
            val hm = timeStr.split(":")
            if (hm.size != 2) return -1
            val h = hm[0].toInt()
            val m = hm[1].toInt()
            
            val now = java.util.Calendar.getInstance()
            val target = java.util.Calendar.getInstance().apply {
                set(java.util.Calendar.HOUR_OF_DAY, h)
                set(java.util.Calendar.MINUTE, m)
                set(java.util.Calendar.SECOND, 0)
                set(java.util.Calendar.MILLISECOND, 0)
            }
            
            if (target.before(now)) {
                0L
            } else {
                target.timeInMillis - now.timeInMillis
            }
        } catch (e: Exception) {
            -1
        }
    }

    private fun cancelAutoSnooze() {
        autoSnoozeRunnable?.let { runnable ->
            autoSnoozeHandler?.removeCallbacks(runnable)
        }
        autoSnoozeRunnable = null
    }

    override fun onDestroy() {
        super.onDestroy()
        cancelAutoSnooze()
        removeOverlay()
        stopForeground(true)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildForegroundNotification(title: String, body: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = nm.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Prayer Overlay Service",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Foreground service for prayer overlay"
                    setSound(null, null)
                }
                nm.createNotificationChannel(channel)
            }
        }
    }

    /**
     * Fungsi untuk memberikan getaran ringan saat overlay muncul
     */
    private fun vibratePhone(attemptCount: Int) {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        vibrator?.let {
            val pattern = when (attemptCount) {
                0 -> longArrayOf(0, 300, 100, 300)           // Overlay 1: ringan
                1 -> longArrayOf(0, 500, 150, 500)           // Overlay 2: sedang
                else -> longArrayOf(0, 800, 200, 800, 200, 800) // Overlay 3: kuat (3x)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(pattern, -1)
                it.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                it.vibrate(pattern, -1)
            }
        }
    }

    /**
     * Menampilkan notifikasi "Missed Prayer" jika user mengabaikan pengingat terakhir
     */
    private fun showMissedNotification(prayerName: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("sholat terlewat")
            .setContentText("kamu belum nandain sholat $prayerName. jangan lupa sholat ya.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        
        nm.notify(MISSED_NOTIFICATION_ID, notification)
    }

    /**
     * Fallback notifikasi biasa jika izin overlay dicabut/gagal tampil
     */
    private fun showFallbackNotification(prayerName: String, message: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Waktu $prayerName")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .build()
        
        nm.notify(FALLBACK_NOTIFICATION_ID, notification)
    }

    companion object {
        private const val CHANNEL_ID = "prayer_overlay_service_channel"
        private const val FOREGROUND_NOTIFICATION_ID = 991
        private const val MISSED_NOTIFICATION_ID = 992
        private const val FALLBACK_NOTIFICATION_ID = 993
    }
}