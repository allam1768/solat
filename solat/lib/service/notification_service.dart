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

  // Notification ID bases
  static const int fajrBaseId = 100;
  static const int dhuhrBaseId = 200;
  static const int asrBaseId = 300;
  static const int maghribBaseId = 400;
  static const int ishaBaseId = 500;

  static const String prayerChannelKey = 'prayer_times_channel';
  static const String prayerChannelName = 'Prayer Times';
  static const String prayerChannelDescription =
      'Notifications for daily prayer times';

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
        'resource://drawable/ic_notification',
        [
          NotificationChannel(
            channelKey: prayerChannelKey,
            channelName: prayerChannelName,
            channelDescription: prayerChannelDescription,
            importance:
                NotificationImportance.Max, // ✅ HARUS Max untuk heads-up
            channelShowBadge: true,
            playSound: true,
            defaultRingtoneType: DefaultRingtoneType.Notification,
            enableVibration: true,
            enableLights: true,
            criticalAlerts: true,
          ),
        ],
        debug: true,
      );

      // Permission is requested in Onboarding

      debugPrint(
          '✅ NotificationService initialized (without permission request)');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
    }
  }

  // ✅ Separate method to request permission (called from Onboarding)
  Future<bool> requestPermissions() async {
    try {
      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

      if (!isAllowed) {
        isAllowed =
            await AwesomeNotifications().requestPermissionToSendNotifications();
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
    required String sunriseTime,
    required String dhuhrTime,
    required String asrTime,
    required String maghribTime,
    required String ishaTime,
  }) async {
    try {
      final profile =
          _storage.read('reminderProfile') ?? 1; // 0 = Basic, 1 = Smart

      // Check if notifications are enabled
      if (!isNotificationEnabled()) {
        debugPrint('Notifications disabled: Cancelling notifications');
        await cancelAllNotifications();
        return;
      }

      // Cancel previous notifications
      await cancelAllNotifications();
      await Future.delayed(const Duration(milliseconds: 300));

      // Helper to schedule a set of notifications for a prayer
      Future<void> scheduleForPrayer({
        required int baseId,
        required String title,
        required String startTime,
        String? endTime,
      }) async {
        if (startTime == '--:--' || startTime == 'Error') return;

        // 1. Start Time
        await _schedulePrayerNotification(
          id: baseId + 1,
          title: ' $title Time',
          body: 'It\'s time for $title prayer.',
          time: startTime,
        );

        // 2. +30 Minutes
        final plus30Time = _addMinutes(startTime, 30);
        if (plus30Time != null) {
          await _schedulePrayerNotification(
            id: baseId + 2,
            title: ' $title Reminder',
            body: '30 minutes have passed since $title started.',
            time: plus30Time,
          );
        }

        // 3. -30 Minutes (Hanya jika profile == 0 / Basic Mode, dan endTime ada)
        if (profile == 0) {
          if (title == 'Isha') {
            final plus60Time = _addMinutes(startTime, 60);
            if (plus60Time != null) {
              await _schedulePrayerNotification(
                id: baseId + 3,
                title: ' $title Ending Soon',
                body:
                    'It has been 60 minutes since $title started. Please pray Isha soon.',
                time: plus60Time,
              );
            }
          } else if (endTime != null &&
              endTime != '--:--' &&
              endTime != 'Error') {
            final minus30Time = _addMinutes(endTime, -30);
            if (minus30Time != null) {
              await _schedulePrayerNotification(
                id: baseId + 3,
                title: ' $title Ending Soon',
                body: 'Only 30 minutes left for $title prayer.',
                time: minus30Time,
              );
            }
          }
        }
      }

      // Jadwalkan untuk setiap waktu sholat
      await scheduleForPrayer(
          baseId: fajrBaseId,
          title: 'Fajr',
          startTime: fajrTime,
          endTime: sunriseTime);
      await scheduleForPrayer(
          baseId: dhuhrBaseId,
          title: 'Dhuhr',
          startTime: dhuhrTime,
          endTime: asrTime);
      await scheduleForPrayer(
          baseId: asrBaseId,
          title: 'Asr',
          startTime: asrTime,
          endTime: maghribTime);
      await scheduleForPrayer(
          baseId: maghribBaseId,
          title: 'Maghrib',
          startTime: maghribTime,
          endTime: ishaTime);
      await scheduleForPrayer(
          baseId: ishaBaseId,
          title: 'Isha',
          startTime: ishaTime,
          endTime: null);

      await checkPendingNotifications();
    } catch (e) {
      debugPrint('❌ Error scheduling prayer notifications: $e');
      rethrow;
    }
  }

  String? _addMinutes(String time, int minutesToAdd) {
    if (time.isEmpty || time == '--:--' || time == 'Error') return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    int totalMinutes = hour * 60 + minute + minutesToAdd;
    if (totalMinutes < 0) totalMinutes += 24 * 60; // mundur ke hari sebelumnya

    int newHour = (totalMinutes ~/ 60) % 24;
    int newMinute = totalMinutes % 60;

    return '${newHour.toString().padLeft(2, '0')}:${newMinute.toString().padLeft(2, '0')}';
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

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: prayerChannelKey,
          title: title,
          body: body,
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          fullScreenIntent: false,
          criticalAlert: true,
          autoDismissible: true,
          displayOnForeground: true,
          displayOnBackground: true,
          locked: false,
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
      await AwesomeNotifications().cancelAllSchedules();
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
      final scheduledNotifications =
          await AwesomeNotifications().listScheduledNotifications();

      if (scheduledNotifications.isEmpty) {
        debugPrint('⚠️ No scheduled notifications found.');
        return;
      }

      debugPrint(
          '📋 Total scheduled notifications: ${scheduledNotifications.length}');
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
          category: NotificationCategory.Reminder,
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
