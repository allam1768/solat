package com.example.solat

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class BasicNotificationReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "onReceive action=$action")

        if (action == ACTION_SHOW_NOTIFICATION) {
            val id = intent.getIntExtra(EXTRA_ID, -1)
            val title = intent.getStringExtra(EXTRA_TITLE) ?: "Prayer Times"
            val body = intent.getStringExtra(EXTRA_BODY) ?: ""

            if (id != -1) {
                showNotification(context, id, title, body)
                // Schedule the exact same notification for tomorrow
                NativeBasicNotificationScheduler.rescheduleForTomorrow(context, id)
            }
        }
    }

    private fun showNotification(context: Context, id: Int, title: String, body: String) {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "prayer_times_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val existing = nm.getNotificationChannel(channelId)
            if (existing == null) {
                val channel = NotificationChannel(
                    channelId,
                    "Prayer Times",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifications for daily prayer times"
                    setShowBadge(true)
                    enableLights(true)
                    enableVibration(true)
                    val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    val audioAttributes = AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build()
                    setSound(uri, audioAttributes)
                }
                nm.createNotificationChannel(channel)
            }
        }

        // Create an intent that opens MainActivity when notification is tapped
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntentFlags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        val pendingIntent = PendingIntent.getActivity(context, id, launchIntent, pendingIntentFlags)

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.drawable.ic_notification) // Use the custom notification icon
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        nm.notify(id, notification)
        Log.d(TAG, "Displayed native basic notification id=$id")
    }

    companion object {
        private const val TAG = "BasicNotifReceiver"
        const val ACTION_SHOW_NOTIFICATION = "com.example.solat.ACTION_SHOW_BASIC_NOTIFICATION"
        const val EXTRA_ID = "extra_id"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_BODY = "extra_body"
    }
}
