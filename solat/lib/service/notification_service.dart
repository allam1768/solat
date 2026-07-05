import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _storage = GetStorage();
  static const platform = MethodChannel('solat/native_notification');

  // Storage key for notification enable/disable
  static const String notificationEnabledKey = 'notification_enabled';
  static const String fridayReminderEnabledKey = 'friday_reminder_enabled';

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
      final isFridayReminderEnabled = 
          _storage.read(fridayReminderEnabledKey) ?? true;
      final isFriday = DateTime.now().weekday == DateTime.friday;

      // Check if notifications are enabled
      if (!isNotificationEnabled()) {
        debugPrint('Notifications disabled: Cancelling notifications');
        await cancelAllNotifications();
        return;
      }

      // Cancel previous notifications
      await cancelAllNotifications();
      await Future.delayed(const Duration(milliseconds: 300));

      List<Map<String, dynamic>> nativeSchedules = [];

      // Helper to schedule a set of notifications for a prayer
      Future<void> scheduleForPrayer({
        required int baseId,
        required String title,
        required String startTime,
        String? endTime,
      }) async {
        if (startTime == '--:--' || startTime == 'Error') return;

        // 1. Start Time
        String prayerKey = title.toLowerCase();
        String translatedName = prayerKey.tr;
        String finalTitle = translatedName;
        String finalBody = Get.locale?.languageCode == 'id'
            ? 'Sudah masuk waktu sholat $translatedName.'
            : 'It\'s time for $translatedName prayer.';

        Map<String, dynamic> scheduleData = {
          'id': baseId + 1,
          'title': finalTitle,
          'body': finalBody,
          'time': startTime,
        };

        if (title == 'Dhuhr') {
          scheduleData['fridayTitle'] = 'friday_prayer'.tr;
          scheduleData['fridayBody'] = Get.locale?.languageCode == 'id'
              ? 'Sudah masuk waktu sholat Jum\'at.'
              : 'It\'s time for Friday prayer.';
        }

        nativeSchedules.add(scheduleData);

        // Friday Preparation Reminders
        if (isFriday && title == 'Dhuhr' && isFridayReminderEnabled) {
          // -50 Minutes
          final minus50Time = _addMinutes(startTime, -50);
          if (minus50Time != null) {
            nativeSchedules.add({
              'id': baseId + 4,
              'title': '${'friday_prep_title'.tr} (50m)',
              'body': 'friday_prep_body'.tr,
              'time': minus50Time,
            });
          }

          // -30 Minutes
          final minus30PrepTime = _addMinutes(startTime, -30);
          if (minus30PrepTime != null) {
            nativeSchedules.add({
              'id': baseId + 5,
              'title': '${'friday_prep_title'.tr} (30m)',
              'body': Get.locale?.languageCode == 'id'
                  ? '30 menit lagi waktu Jumatan. Yuk berangkat ke Masjid!'
                  : '30 minutes until Friday prayer. Time to go to the mosque!',
              'time': minus30PrepTime,
            });
          }
        }

        // 2. +30 Minutes
        final plus30Time = _addMinutes(startTime, 30);
        if (plus30Time != null) {
          String reminderTitle = Get.locale?.languageCode == 'id'
              ? 'Pengingat $translatedName'
              : '$translatedName Reminder';
          String reminderBody = Get.locale?.languageCode == 'id'
              ? 'Sudah 30 menit sejak waktu $translatedName dimulai.'
              : '30 minutes have passed since $translatedName started.';

          Map<String, dynamic> reminderData = {
            'id': baseId + 2,
            'title': reminderTitle,
            'body': reminderBody,
            'time': plus30Time,
          };

          if (title == 'Dhuhr') {
            reminderData['fridayTitle'] = Get.locale?.languageCode == 'id' 
                ? 'Pengingat Jumatan' 
                : 'Friday Prayer Reminder';
            reminderData['fridayBody'] = Get.locale?.languageCode == 'id'
                ? 'Sudah 30 menit sejak waktu Jum\'at dimulai.'
                : '30 minutes have passed since Friday prayer started.';
          }

          nativeSchedules.add(reminderData);
        }

        // 3. -30 Minutes (Hanya jika profile == 0 / Basic Mode, dan endTime ada)
        if (profile == 0) {
          if (title == 'Isha') {
            final plus60Time = _addMinutes(startTime, 60);
            if (plus60Time != null) {
              String endingTitle = Get.locale?.languageCode == 'id'
                  ? 'Waktu $translatedName Akan Habis'
                  : '$translatedName Ending Soon';
              String endingBody = Get.locale?.languageCode == 'id'
                  ? 'Sudah 60 menit sejak $translatedName dimulai. Yuk sholat Isya sekarang.'
                  : 'It has been 60 minutes since $translatedName started. Please pray Isha soon.';

              nativeSchedules.add({
                'id': baseId + 3,
                'title': endingTitle,
                'body': endingBody,
                'time': plus60Time,
              });
            }
          } else if (endTime != null &&
              endTime != '--:--' &&
              endTime != 'Error') {
            final minus30Time = _addMinutes(endTime, -30);
            if (minus30Time != null) {
              String endingTitle = Get.locale?.languageCode == 'id'
                  ? 'Waktu $translatedName Akan Habis'
                  : '$translatedName Ending Soon';
              String endingBody = Get.locale?.languageCode == 'id'
                  ? 'Hanya tersisa 30 menit untuk waktu $translatedName.'
                  : 'Only 30 minutes left for $translatedName prayer.';

              nativeSchedules.add({
                'id': baseId + 3,
                'title': endingTitle,
                'body': endingBody,
                'time': minus30Time,
              });
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

      // Kirim semua jadwal ke Android Native
      await platform.invokeMethod('scheduleBasicNotifications', {
        'schedules': nativeSchedules,
      });

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

  // Remove _schedulePrayerNotification as it is no longer used


  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAllSchedules();
      await platform.invokeMethod('cancelBasicNotifications');
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
