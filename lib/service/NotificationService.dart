import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _storage = GetStorage();

  // Storage key untuk notification enable/disable
  static const String notificationEnabledKey = 'notification_enabled';

  static const int fajrNotificationId = 1;
  static const int dhuhrNotificationId = 2;
  static const int asrNotificationId = 3;
  static const int maghribNotificationId = 4;
  static const int ishaNotificationId = 5;

  static const String prayerChannelKey = 'prayer_times_channel';
  static const String prayerChannelName = 'Waktu Sholat';
  static const String prayerChannelDescription = 'Notifikasi untuk waktu sholat';

  // Check if notification is enabled
  bool isNotificationEnabled() {
    return _storage.read(notificationEnabledKey) ?? true;
  }

  // Set notification enabled/disabled
  Future<void> setNotificationEnabled(bool enabled) async {
    await _storage.write(notificationEnabledKey, enabled);
  }

  Future<void> initialize() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: prayerChannelKey,
            channelName: prayerChannelName,
            channelDescription: prayerChannelDescription,
            importance: NotificationImportance.Default,
            channelShowBadge: true,
            playSound: false,
            enableVibration: true,
            enableLights: false,
            criticalAlerts: false,
          ),
        ],
        debug: true,
      );

      await requestPermissions();

      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

      if (!isAllowed) {
        isAllowed = await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      if (!isAllowed) {
        debugPrint('❌ Notification permission DENIED');
        return false;
      }

      debugPrint('✅ All permissions granted: $isAllowed');
      return isAllowed;
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> schedulePrayerNotifications({
    required String fajrTime,
    required String dhuhrTime,
    required String asrTime,
    required String maghribTime,
    required String ishaTime,
  }) async {
    try {
      // Cek apakah notifikasi diaktifkan
      if (!isNotificationEnabled()) {
        debugPrint('🚫 Notifikasi dimatikan, skip scheduling');
        await cancelAllNotifications(); // Cancel jika ada yang terjadwal
        return;
      }

      // Cancel semua notifikasi sebelumnya
      await cancelAllNotifications();

      // Delay sebentar untuk memastikan cancel selesai
      await Future.delayed(const Duration(milliseconds: 300));

      // Schedule setiap waktu sholat
      await _schedulePrayerNotification(
        id: fajrNotificationId,
        title: '🕌 Waktu Subuh',
        body: 'Sudah masuk waktu sholat Subuh. Ayo segera sholat!',
        time: fajrTime,
      );

      await _schedulePrayerNotification(
        id: dhuhrNotificationId,
        title: '🕌 Waktu Dzuhur',
        body: 'Sudah masuk waktu sholat Dzuhur. Ayo segera sholat!',
        time: dhuhrTime,
      );

      await _schedulePrayerNotification(
        id: asrNotificationId,
        title: '🕌 Waktu Ashar',
        body: 'Sudah masuk waktu sholat Ashar. Ayo segera sholat!',
        time: asrTime,
      );

      await _schedulePrayerNotification(
        id: maghribNotificationId,
        title: '🕌 Waktu Maghrib',
        body: 'Sudah masuk waktu sholat Maghrib. Ayo segera sholat!',
        time: maghribTime,
      );

      await _schedulePrayerNotification(
        id: ishaNotificationId,
        title: '🕌 Waktu Isya',
        body: 'Sudah masuk waktu sholat Isya. Ayo segera sholat!',
        time: ishaTime,
      );

      debugPrint('✅ Semua notifikasi waktu sholat berhasil dijadwalkan');

      await checkPendingNotifications();
    } catch (e) {
      debugPrint('❌ Error scheduling prayer notifications: $e');
      rethrow;
    }
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required String time,
  }) async {
    try {
      final timeParts = time.split(':');
      if (timeParts.length != 2) {
        debugPrint('❌ Format waktu tidak valid: $time');
        return;
      }

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: prayerChannelKey,
          title: title,
          body: body,
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          fullScreenIntent: true,
          criticalAlert: true,
          autoDismissible: false,
          displayOnForeground: true,
          displayOnBackground: true,
          locked: true,
          color: const Color(0xFF009688),
          backgroundColor: Colors.white,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Tutup',
            autoDismissible: true,
          ),
        ],
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      if (created) {
        debugPrint('✅ Notifikasi dijadwalkan: $title pada ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (ID: $id, Repeats: true)');
      } else {
        debugPrint('⚠️ Notifikasi dijadwalkan (native): $title pada ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (ID: $id)');
      }
    } catch (e) {
      debugPrint('❌ Error scheduling notification for $title: $e');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancel(fajrNotificationId);
      await AwesomeNotifications().cancel(dhuhrNotificationId);
      await AwesomeNotifications().cancel(asrNotificationId);
      await AwesomeNotifications().cancel(maghribNotificationId);
      await AwesomeNotifications().cancel(ishaNotificationId);
      debugPrint('🗑️ Semua notifikasi waktu sholat dibatalkan');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
      debugPrint('🗑️ Notifikasi #$id dibatalkan');
    } catch (e) {
      debugPrint('❌ Error cancelling notification #$id: $e');
    }
  }

  Future<void> checkPendingNotifications() async {
    try {
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();

      debugPrint('📋 === SCHEDULED NOTIFICATIONS === ');
      debugPrint('Total: ${scheduledNotifications.length}');

      if (scheduledNotifications.isEmpty) {
        debugPrint('⚠️ TIDAK ADA NOTIFIKASI TERJADWAL!');
        return;
      }

      for (var notification in scheduledNotifications) {
        final content = notification.content;
        final schedule = notification.schedule;

        if (content != null) {
          debugPrint('  ✓ ID: ${content.id}, Title: ${content.title}');
        }

        if (schedule is NotificationCalendar) {
          debugPrint('    Schedule: ${schedule.hour?.toString().padLeft(2, '0')}:${schedule.minute?.toString().padLeft(2, '0')}, Repeats: ${schedule.repeats}');
        }
      }
      debugPrint('================================');
    } catch (e) {
      debugPrint('❌ Error checking pending notifications: $e');
    }
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 999,
          channelKey: prayerChannelKey,
          title: title,
          body: body,
          category: NotificationCategory.Message,
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: true,
          displayOnBackground: true,
          wakeUpScreen: true,
          color: const Color(0xFF009688),
        ),
      );

      debugPrint('✅ Instant notification sent: $title');
    } catch (e) {
      debugPrint('❌ Error sending instant notification: $e');
    }
  }
}