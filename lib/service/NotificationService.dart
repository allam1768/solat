import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _storage = GetStorage();

  // Storage key for notification enable/disable
  static const String notificationEnabledKey = 'notification_enabled';

  static const int fajrNotificationId = 1;
  static const int dhuhrNotificationId = 2;
  static const int asrNotificationId = 3;
  static const int maghribNotificationId = 4;
  static const int ishaNotificationId = 5;

  static const String prayerChannelKey = 'prayer_times_channel';
  static const String prayerChannelName = 'Prayer Times';
  static const String prayerChannelDescription = 'Notifications for daily prayer times';

  // Check if notification is enabled
  bool isNotificationEnabled() {
    return _storage.read(notificationEnabledKey) ?? false; // ✅ Default false
  }

  // Set notification enabled/disabled
  Future<void> setNotificationEnabled(bool enabled) async {
    if (enabled) {
      // Request permission when enabling
      final granted = await requestPermissions();
      if (granted) {
        await _storage.write(notificationEnabledKey, true);
      }
    } else {
      await _storage.write(notificationEnabledKey, false);
    }
  }

  // ✅ Initialize WITHOUT auto-requesting permission
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

      // Permission is requested in Onboarding

      debugPrint('✅ NotificationService initialized (without permission request)');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  // ✅ Separate method to request permission (called from Onboarding)
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

      debugPrint('✅ Notification permission GRANTED');
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
      // Check if notifications are enabled
      if (!isNotificationEnabled()) {
        await cancelAllNotifications();
        return;
      }

      // Cancel previous notifications
      await cancelAllNotifications();

      // Small delay to ensure cancellations complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Schedule each prayer time
      await _schedulePrayerNotification(
        id: fajrNotificationId,
        title: '🕌 Fajr Time',
        body: 'It\'s time for Fajr prayer.',
        time: fajrTime,
      );

      await _schedulePrayerNotification(
        id: dhuhrNotificationId,
        title: '🕌 Dhuhr Time',
        body: 'It\'s time for Dhuhr prayer.',
        time: dhuhrTime,
      );

      await _schedulePrayerNotification(
        id: asrNotificationId,
        title: '🕌 Asr Time',
        body: 'It\'s time for Asr prayer.',
        time: asrTime,
      );

      await _schedulePrayerNotification(
        id: maghribNotificationId,
        title: '🕌 Maghrib Time',
        body: 'It\'s time for Maghrib prayer.',
        time: maghribTime,
      );

      await _schedulePrayerNotification(
        id: ishaNotificationId,
        title: '🕌 Isha Time',
        body: 'It\'s time for Isha prayer.',
        time: ishaTime,
      );

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
        debugPrint('❌ Invalid time format: $time');
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
            label: 'Dismiss',
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
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await AwesomeNotifications().cancel(id);
    } catch (e) {
      debugPrint('❌ Error cancelling notification #$id: $e');
    }
  }

  Future<void> checkPendingNotifications() async {
    try {
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();

      if (scheduledNotifications.isEmpty) {
        debugPrint('⚠️ No scheduled notifications found.');
        return;
      }

      debugPrint('📋 Total scheduled notifications: ${scheduledNotifications.length}');
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
    } catch (e) {
      debugPrint('❌ Error sending instant notification: $e');
    }
  }
}