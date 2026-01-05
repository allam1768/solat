import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'OverlayService.dart';

class OverlaySchedulerService {
  static final OverlaySchedulerService _instance = OverlaySchedulerService._internal();
  factory OverlaySchedulerService() => _instance;
  OverlaySchedulerService._internal();

  final OverlayService _overlayService = OverlayService();

  // Notification IDs untuk overlay triggers
  static const int subuhOverlayId = 101;
  static const int dhuhrOverlayId = 102;
  static const int asrOverlayId = 103;
  static const int maghribOverlayId = 104;
  static const int ishaOverlayId = 105;

  static const String overlayChannelKey = 'prayer_overlay_channel';
  static const String overlayChannelName = 'Prayer Overlay Triggers';

  Future<void> initializeOverlayChannel() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: overlayChannelKey,
            channelName: overlayChannelName,
            channelDescription: 'Silent triggers for prayer overlays',
            importance: NotificationImportance.Min,
            channelShowBadge: false,
            playSound: false,
            enableVibration: false,
            enableLights: false,
            criticalAlerts: false,
          ),
        ],
        debug: true,
      );

      debugPrint('✅ Overlay channel initialized');
    } catch (e) {
      debugPrint('❌ Error initializing overlay channel: $e');
    }
  }

  Future<void> scheduleOverlayTriggers({
    required String fajrTime,
    required String sunriseTime,
    required String dhuhrTime,
    required String asrTime,
    required String maghribTime,
    required String ishaTime,
  }) async {
    try {
      if (!_overlayService.isOverlayEnabled()) {
        debugPrint('🚫 Overlay disabled, skipping scheduling');
        return;
      }

      // Cancel previous overlay schedules
      await cancelAllOverlayTriggers();

      await Future.delayed(const Duration(milliseconds: 300));

      // 1. Subuh: 30 menit sebelum terbit (sunrise - 30 min)
      await _scheduleOverlayTrigger(
        id: subuhOverlayId,
        targetTime: sunriseTime,
        offsetMinutes: -30,
        prayerName: 'Subuh',
        message: 'Waktu Subuh akan berakhir dalam 30 menit!\nAyo segera sholat Subuh.',
        nextPrayerName: 'Dzuhur',
        nextPrayerTime: dhuhrTime,
      );

      // 2. Dzuhur: 30 menit sebelum ashar (asr - 30 min)
      await _scheduleOverlayTrigger(
        id: dhuhrOverlayId,
        targetTime: asrTime,
        offsetMinutes: -30,
        prayerName: 'Dzuhur',
        message: 'Waktu Dzuhur akan berakhir dalam 30 menit!\nAyo segera sholat Dzuhur.',
        nextPrayerName: 'Ashar',
        nextPrayerTime: asrTime,
      );

      // 3. Ashar: 30 menit sebelum maghrib (maghrib - 30 min)
      await _scheduleOverlayTrigger(
        id: asrOverlayId,
        targetTime: maghribTime,
        offsetMinutes: -30,
        prayerName: 'Ashar',
        message: 'Waktu Ashar akan berakhir dalam 30 menit!\nAyo segera sholat Ashar.',
        nextPrayerName: 'Maghrib',
        nextPrayerTime: maghribTime,
      );

      // 4. Maghrib: 30 menit sebelum isya (isha - 30 min)
      await _scheduleOverlayTrigger(
        id: maghribOverlayId,
        targetTime: ishaTime,
        offsetMinutes: -30,
        prayerName: 'Maghrib',
        message: 'Waktu Maghrib akan berakhir dalam 30 menit!\nAyo segera sholat Maghrib.',
        nextPrayerName: 'Isya',
        nextPrayerTime: ishaTime,
      );

      // 5. Isya: 30 menit SETELAH isya (isha + 30 min)
      await _scheduleOverlayTrigger(
        id: ishaOverlayId,
        targetTime: ishaTime,
        offsetMinutes: 30, // Positive offset = after
        prayerName: 'Isya',
        message: 'Sudah 30 menit sejak masuk waktu Isya!\nAyo segera sholat Isya.',
        nextPrayerName: 'Subuh',
        nextPrayerTime: fajrTime,
      );

      debugPrint('✅ All overlay triggers scheduled');
      await checkScheduledOverlays();
    } catch (e) {
      debugPrint('❌ Error scheduling overlay triggers: $e');
      rethrow;
    }
  }

  Future<void> _scheduleOverlayTrigger({
    required int id,
    required String targetTime,
    required int offsetMinutes,
    required String prayerName,
    required String message,
    required String nextPrayerName,
    required String nextPrayerTime,
  }) async {
    try {
      final timeParts = targetTime.split(':');
      if (timeParts.length != 2) {
        debugPrint('❌ Invalid time format: $targetTime');
        return;
      }

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      // Apply offset
      minute += offsetMinutes;

      // Handle minute overflow/underflow
      while (minute >= 60) {
        minute -= 60;
        hour += 1;
      }
      while (minute < 0) {
        minute += 60;
        hour -= 1;
      }

      // Handle hour overflow/underflow
      if (hour >= 24) hour -= 24;
      if (hour < 0) hour += 24;

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Create silent notification as trigger
      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: overlayChannelKey,
          title: 'overlay_trigger', // Marker for overlay
          body: '$prayerName|$message|$nextPrayerName $nextPrayerTime',
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          displayOnForeground: false,
          displayOnBackground: false,
          showWhen: false,
          autoDismissible: true,
          payload: {
            'type': 'overlay_trigger',
            'prayerName': prayerName,
            'message': message,
            'nextPrayerName': nextPrayerName,
            'nextPrayerTime': nextPrayerTime,
          },
        ),
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
        debugPrint('✅ Overlay trigger scheduled: $prayerName at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (ID: $id)');
      } else {
        debugPrint('⚠️ Overlay trigger scheduled (native): $prayerName at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} (ID: $id)');
      }
    } catch (e) {
      debugPrint('❌ Error scheduling overlay trigger for $prayerName: $e');
      rethrow;
    }
  }

  Future<void> cancelAllOverlayTriggers() async {
    try {
      await AwesomeNotifications().cancel(subuhOverlayId);
      await AwesomeNotifications().cancel(dhuhrOverlayId);
      await AwesomeNotifications().cancel(asrOverlayId);
      await AwesomeNotifications().cancel(maghribOverlayId);
      await AwesomeNotifications().cancel(ishaOverlayId);

      debugPrint('🗙️ All overlay triggers cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling overlay triggers: $e');
    }
  }

  Future<void> checkScheduledOverlays() async {
    try {
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();

      final overlayTriggers = scheduledNotifications.where((n) =>
      n.content?.channelKey == overlayChannelKey
      ).toList();

      debugPrint('📋 === OVERLAY TRIGGERS === ');
      debugPrint('Total: ${overlayTriggers.length}');

      if (overlayTriggers.isEmpty) {
        debugPrint('⚠️ NO OVERLAY TRIGGERS SCHEDULED!');
        return;
      }

      for (var notification in overlayTriggers) {
        final content = notification.content;
        final schedule = notification.schedule;

        if (content != null) {
          debugPrint('  ✔ ID: ${content.id}, Prayer: ${content.payload?['prayerName']}');
        }

        if (schedule is NotificationCalendar) {
          debugPrint('    Time: ${schedule.hour?.toString().padLeft(2, '0')}:${schedule.minute?.toString().padLeft(2, '0')}, Repeats: ${schedule.repeats}');
        }
      }
      debugPrint('==========================');
    } catch (e) {
      debugPrint('❌ Error checking overlay triggers: $e');
    }
  }
}