package com.example.solat

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

        val prayerName = intent.getStringExtra(PrayerAlarmReceiver.EXTRA_PRAYER_NAME) ?: "Prayer"
        val message = intent.getStringExtra(PrayerAlarmReceiver.EXTRA_MESSAGE)
            ?: "It's time for $prayerName"
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
            setPadding(24.dp(), 0, 24.dp(), 0) // horizontal 24dp
        }

        // ========================================
        // CARD CONTAINER
        // ========================================
        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(20.dp(), 20.dp(), 20.dp(), 20.dp()) // padding 20dp
            gravity = Gravity.CENTER

            // Constraints: maxWidth 340, minWidth 300
            layoutParams = LinearLayout.LayoutParams(
                340.dp(), // maxWidth
                LinearLayout.LayoutParams.WRAP_CONTENT
            )

            // Rounded rectangle dengan border dan shadow
            val drawable = android.graphics.drawable.GradientDrawable().apply {
                shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                setColor(Color.WHITE)
                cornerRadius = 15f.dp().toFloat() // 15dp rounded
                setStroke(1.5f.dp(), Color.BLACK) // 1.5dp border
            }
            background = drawable

            // Shadow effect
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                elevation = 15f.dp().toFloat()
            }
        }

        // ========================================
        // LOGO ICON
        // ========================================
        val iconView = android.widget.ImageView(ctx).apply {
            setImageResource(R.drawable.ic_moon_star) // Ganti ke logo.svg kalau sudah ada
            setColorFilter(Color.BLACK) // ColorFilter mode srcIn
            layoutParams = LinearLayout.LayoutParams(100.dp(), 100.dp())
        }

        // ========================================
        // PRAYER NAME TITLE
        // ========================================
        val titleView = TextView(ctx).apply {
            text = prayerName
            textSize = 24f
            setTextColor(Color.BLACK)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 40.dp(), 0, 12.dp()) // top 40dp, bottom 12dp
        }

        // ========================================
        // MESSAGE TEXT (DYNAMIC)
        // ========================================
        val dynamicMessage = if (baseTime.isNotEmpty()) {
            if (prayerName == "Isya") {
                val diff = getMinutesDifference(baseTime, isPast = true)
                if (diff >= 0) {
                    val unit = if (diff == 1) "minute" else "minutes"
                    "It has been $diff $unit since $prayerName started.\nPlease pray $prayerName soon."
                } else message
            } else {
                val diff = getMinutesDifference(baseTime, isPast = false)
                val unit = if (diff == 1) "minute" else "minutes"
                when {
                    diff > 0 -> "$prayerName time will end in $diff $unit!\nPlease pray $prayerName soon."
                    diff == 0 -> "$prayerName time is ending now!\nPlease pray $prayerName immediately."
                    else -> "$prayerName time has ended!\nPlease pray $prayerName as soon as possible."
                }
            }
        } else {
            message
        }

        val messageView = TextView(ctx).apply {
            text = dynamicMessage
            textSize = 13f
            setTextColor(Color.BLACK)
            typeface = Typeface.create(Typeface.DEFAULT, 600, false) // fontWeight w600
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 40.dp()) // bottom 40dp
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

            // ✅ "I've prayed" BUTTON (Full Width)
            val doneButton = Button(ctx).apply {
                text = "I've prayed"
                textSize = 14f
                setTextColor(Color.BLACK)
                typeface = Typeface.create(Typeface.DEFAULT, 600, false)
                setPadding(0, 4.dp(), 0, 4.dp()) // vertical 4dp
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.WHITE)
                    cornerRadius = 10f.dp().toFloat()
                    setStroke(2.dp(), Color.BLACK)
                }

                isAllCaps = false
                stateListAnimator = null

                // ✅ Besok sudah auto-dijadwalkan saat overlay muncul, cukup tutup
                setOnClickListener {
                    removeOverlay()
                    stopSelf()
                }
            }

            // ✅ Spacing 8dp
            val spacer1 = android.view.View(ctx).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    8.dp()
                )
            }

            // ✅ "On my way" BUTTON (Full Width)
            val onMyWayButton = Button(ctx).apply {
                text = "On my way"
                textSize = 14f
                setTextColor(Color.BLACK)
                typeface = Typeface.create(Typeface.DEFAULT, 600, false)
                setPadding(0, 4.dp(), 0, 4.dp())
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.WHITE)
                    cornerRadius = 10f.dp().toFloat()
                    setStroke(2.dp(), Color.BLACK)
                }

                isAllCaps = false
                stateListAnimator = null

                // ✅ UPDATED: Cukup tutup overlay
                setOnClickListener {
                    removeOverlay()
                    stopSelf()
                }
            }

            // Add all vertical buttons
            buttonsContainer.addView(doneButton)
            buttonsContainer.addView(spacer1)
            buttonsContainer.addView(onMyWayButton)

            // Add to card
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

            // ✅ "I've prayed" BUTTON
            val doneButton = Button(ctx).apply {
                text = "I've prayed"
                textSize = 14f
                setTextColor(Color.BLACK)
                typeface = Typeface.create(Typeface.DEFAULT, 600, false)
                setPadding(0, 4.dp(), 0, 4.dp()) // vertical 4dp
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply {
                    setMargins(0, 0, 12.dp(), 0) // spacing 12dp
                }

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.WHITE)
                    cornerRadius = 10f.dp().toFloat()
                    setStroke(2.dp(), Color.BLACK)
                }

                isAllCaps = false
                stateListAnimator = null

                // ✅ Besok akan auto-dijadwalkan di overlay terakhir, cukup tutup
                setOnClickListener {
                    removeOverlay()
                    stopSelf()
                }
            }

            // ✅ "Later" BUTTON
            val laterButton = Button(ctx).apply {
                text = "Later"
                textSize = 14f
                setTextColor(Color.BLACK)
                typeface = Typeface.create(Typeface.DEFAULT, 600, false)
                setPadding(0, 4.dp(), 0, 4.dp())
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                )

                background = android.graphics.drawable.GradientDrawable().apply {
                    shape = android.graphics.drawable.GradientDrawable.RECTANGLE
                    setColor(Color.WHITE)
                    cornerRadius = 10f.dp().toFloat()
                    setStroke(2.dp(), Color.BLACK)
                }

                isAllCaps = false
                stateListAnimator = null

                // ✅ Snooze saja tanpa schedule besok (besok akan dijadwalkan saat user klik "I've prayed")
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

            // Add to card
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

        windowManager?.addView(root, layoutParams)
        overlayView = root
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
            // Hitung sisa waktu sampai sholat berikutnya (auto-close saat sholat selanjutnya masuk)
            getMillisUntil(nextPrayerTime).let { 
                if (it >= 0) it else 3600000 // Fallback 1 jam kalau gagal parse
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
                return 0L // Sudah lewat, tutup sekarang
            }
            
            target.timeInMillis - now.timeInMillis
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
            .setContentTitle("Missed Prayer")
            .setContentText("You didn't mark $prayerName as done. Please don't forget to pray.")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        
        nm.notify(MISSED_NOTIFICATION_ID, notification)
    }

    companion object {
        private const val CHANNEL_ID = "prayer_overlay_service_channel"
        private const val FOREGROUND_NOTIFICATION_ID = 991
        private const val MISSED_NOTIFICATION_ID = 992
    }
}