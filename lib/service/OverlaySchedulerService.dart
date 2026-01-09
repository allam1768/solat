import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'OverlayService.dart';

class OverlaySchedulerService {
  static final OverlaySchedulerService _instance = OverlaySchedulerService._internal();
  factory OverlaySchedulerService() => _instance;
  OverlaySchedulerService._internal();

  final OverlayService _overlayService = OverlayService();

  // Base notification IDs untuk overlay triggers (100-105)
  static const int subuhOverlayId = 101;
  static const int dhuhrOverlayId = 102;
  static const int asrOverlayId = 103;
  static const int maghribOverlayId = 104;
  static const int ishaOverlayId = 105;

  // Dynamic snooze IDs (200+)
  static const int snoozeIdBase = 200;

  // ✅ Channel Keys
  static const String overlayChannelKey = 'prayer_overlay_channel'; // Silent untuk schedule harian
  static const String alarmChannelKey = 'prayer_overlay_alarm'; // LOUD untuk snooze

  Future<void> initializeOverlayChannel() async {
    try {
      await AwesomeNotifications().initialize(
        null,
        [
          // ✅ Channel 1: Silent trigger untuk schedule harian
          NotificationChannel(
            channelKey: overlayChannelKey,
            channelName: 'Prayer Overlay Triggers',
            channelDescription: 'Silent triggers for daily prayer overlays',
            importance: NotificationImportance.Min,
            channelShowBadge: false,
            playSound: false,
            enableVibration: false,
            enableLights: false,
            criticalAlerts: false,
          ),

          // ✅ Channel 2: ALARM untuk snooze (FULL SCREEN INTENT)
          NotificationChannel(
            channelKey: alarmChannelKey,
            channelName: 'Prayer Reminder Alarm',
            channelDescription: 'Urgent prayer reminders with full screen notification',
            importance: NotificationImportance.Max,
            channelShowBadge: true,
            playSound: true,
            soundSource: 'resource://raw/alarm_sound', // Optional: custom sound
            enableVibration: true,
            vibrationPattern: highVibrationPattern,
            enableLights: true,
            ledColor: Colors.red,
            ledOnMs: 1000,
            ledOffMs: 500,
            criticalAlerts: true, // ✅ iOS & Android 10+
            defaultColor: Colors.red,
            defaultRingtoneType: DefaultRingtoneType.Alarm,
          ),
        ],
        debug: true,
      );

      debugPrint('✅ Overlay channels initialized');
      debugPrint('   📢 Silent Channel: $overlayChannelKey');
      debugPrint('   🚨 Alarm Channel: $alarmChannelKey');
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
      await cancelAllOverlayTriggers();
      await Future.delayed(const Duration(milliseconds: 300));

      // Schedule dengan SILENT channel (repeating daily)
      await _scheduleOverlayTrigger(
        id: subuhOverlayId,
        targetTime: sunriseTime,
        offsetMinutes: -30,
        prayerName: 'Subuh',
        message: 'Waktu Subuh akan berakhir dalam 30 menit!\nAyo segera sholat Subuh.',
        nextPrayerName: 'Dzuhur',
        nextPrayerTime: dhuhrTime,
        channelKey: overlayChannelKey, // Silent
      );

      await _scheduleOverlayTrigger(
        id: dhuhrOverlayId,
        targetTime: asrTime,
        offsetMinutes: -30,
        prayerName: 'Dzuhur',
        message: 'Waktu Dzuhur akan berakhir dalam 30 menit!\nAyo segera sholat Dzuhur.',
        nextPrayerName: 'Ashar',
        nextPrayerTime: asrTime,
        channelKey: overlayChannelKey,
      );

      await _scheduleOverlayTrigger(
        id: asrOverlayId,
        targetTime: maghribTime,
        offsetMinutes: -30,
        prayerName: 'Ashar',
        message: 'Waktu Ashar akan berakhir dalam 30 menit!\nAyo segera sholat Ashar.',
        nextPrayerName: 'Maghrib',
        nextPrayerTime: maghribTime,
        channelKey: overlayChannelKey,
      );

      await _scheduleOverlayTrigger(
        id: maghribOverlayId,
        targetTime: ishaTime,
        offsetMinutes: -30,
        prayerName: 'Maghrib',
        message: 'Waktu Maghrib akan berakhir dalam 30 menit!\nAyo segera sholat Maghrib.',
        nextPrayerName: 'Isya',
        nextPrayerTime: ishaTime,
        channelKey: overlayChannelKey,
      );

      await _scheduleOverlayTrigger(
        id: ishaOverlayId,
        targetTime: ishaTime,
        offsetMinutes: 30,
        prayerName: 'Isya',
        message: 'Sudah 30 menit sejak masuk waktu Isya!\nAyo segera sholat Isya.',
        nextPrayerName: 'Subuh',
        nextPrayerTime: fajrTime,
        channelKey: overlayChannelKey,
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
    required String channelKey,
  }) async {
    try {
      final timeParts = targetTime.split(':');
      if (timeParts.length != 2) {
        debugPrint('❌ Invalid time format: $targetTime');
        return;
      }

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      minute += offsetMinutes;

      while (minute >= 60) {
        minute -= 60;
        hour += 1;
      }
      while (minute < 0) {
        minute += 60;
        hour -= 1;
      }

      if (hour >= 24) hour -= 24;
      if (hour < 0) hour += 24;

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _overlayService.resetAttempt(prayerName);

      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: channelKey,
          title: 'overlay_trigger',
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
      }
    } catch (e) {
      debugPrint('❌ Error scheduling overlay trigger for $prayerName: $e');
      rethrow;
    }
  }

  // ✅ Schedule snooze dengan ALARM channel (Full Screen Intent)
  Future<void> scheduleSnoozeOverlay({
    required String prayerName,
    required String message,
    required String nextPrayerName,
    required String nextPrayerTime,
  }) async {
    try {
      await _overlayService.incrementAttempt(prayerName);

      final now = DateTime.now();
      final attempt = _overlayService.getAttemptCount(prayerName);

      // Dynamic snooze duration
      int snoozeMinutes;
      if (attempt == 0) {
        snoozeMinutes = 5;
      } else if (attempt == 1) {
        snoozeMinutes = 5;
      } else {
        snoozeMinutes = 3;
      }

      final snoozeTime = now.add(Duration(minutes: snoozeMinutes));
      final snoozeId = snoozeIdBase + (prayerName.hashCode % 50);

      debugPrint('⏰ === SCHEDULING SNOOZE ALARM ===');
      debugPrint('   Prayer: $prayerName');
      debugPrint('   Attempt: ${attempt + 1}');
      debugPrint('   Snooze: $snoozeMinutes minutes');
      debugPrint('   Time: ${snoozeTime.hour}:${snoozeTime.minute.toString().padLeft(2, '0')}');
      debugPrint('   ID: $snoozeId');
      debugPrint('   Channel: $alarmChannelKey (ALARM MODE)');

      await AwesomeNotifications().cancel(snoozeId);
      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ CREATE ALARM NOTIFICATION with Full Screen Intent
      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: snoozeId,
          channelKey: alarmChannelKey, // ✅ ALARM CHANNEL
          title: '⏰ Waktu Sholat $prayerName',
          body: 'Segera sholat $prayerName sebelum waktu habis!',
          summary: 'Pengingat ke-${attempt + 1}',
          category: NotificationCategory.Alarm, // ✅ ALARM CATEGORY
          notificationLayout: NotificationLayout.BigText,

          // ✅ CRITICAL FLAGS untuk Full Screen Intent
          criticalAlert: true,
          fullScreenIntent: true,
          wakeUpScreen: true,
          locked: true,

          // Visual
          color: Colors.red,
          backgroundColor: Colors.red,

          // Persistence
          autoDismissible: false,
          displayOnForeground: true,
          displayOnBackground: true,
          showWhen: true,

          payload: {
            'type': 'overlay_trigger',
            'prayerName': prayerName,
            'message': message,
            'nextPrayerName': nextPrayerName,
            'nextPrayerTime': nextPrayerTime,
            'isSnooze': 'true',
            'attempt': attempt.toString(),
          },
        ),
        schedule: NotificationCalendar(
          year: snoozeTime.year,
          month: snoozeTime.month,
          day: snoozeTime.day,
          hour: snoozeTime.hour,
          minute: snoozeTime.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'DONE',
            label: 'Sudah Sholat',
            actionType: ActionType.Default,
            autoDismissible: true,
          ),
          NotificationActionButton(
            key: 'SNOOZE',
            label: 'Ingatkan Lagi (${snoozeMinutes}m)',
            actionType: ActionType.Default,
            autoDismissible: true,
          ),
        ],
      );

      if (created) {
        debugPrint('✅ Snooze ALARM scheduled successfully!');
        debugPrint('   Will trigger at: ${snoozeTime.hour}:${snoozeTime.minute.toString().padLeft(2, '0')}');
        debugPrint('   Full Screen Intent: ENABLED');
      } else {
        debugPrint('⚠️ Snooze alarm created (native handling)');
      }

      debugPrint('✅ === SNOOZE ALARM COMPLETE ===');

    } catch (e, stack) {
      debugPrint('❌ Error scheduling snooze alarm: $e');
      debugPrint('Stack: $stack');
    }
  }

  Future<void> handlePrayerDone(String prayerName) async {
    try {
      debugPrint('✅ Prayer done for $prayerName, resetting attempts');

      await _overlayService.resetAttempt(prayerName);

      final snoozeId = snoozeIdBase + (prayerName.hashCode % 50);
      await AwesomeNotifications().cancel(snoozeId);

      debugPrint('✅ Attempts reset and snooze cancelled for $prayerName');
    } catch (e) {
      debugPrint('❌ Error handling prayer done: $e');
    }
  }

  Future<void> cancelAllOverlayTriggers() async {
    try {
      await AwesomeNotifications().cancel(subuhOverlayId);
      await AwesomeNotifications().cancel(dhuhrOverlayId);
      await AwesomeNotifications().cancel(asrOverlayId);
      await AwesomeNotifications().cancel(maghribOverlayId);
      await AwesomeNotifications().cancel(ishaOverlayId);

      for (int i = snoozeIdBase; i < snoozeIdBase + 50; i++) {
        await AwesomeNotifications().cancel(i);
      }

      debugPrint('🗑️ All overlay triggers cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling overlay triggers: $e');
    }
  }

  Future<void> checkScheduledOverlays() async {
    try {
      final scheduledNotifications = await AwesomeNotifications().listScheduledNotifications();

      final overlayTriggers = scheduledNotifications.where((n) =>
      n.content?.channelKey == overlayChannelKey ||
          n.content?.channelKey == alarmChannelKey
      ).toList();

      debugPrint('📋 === OVERLAY TRIGGERS ===');
      debugPrint('Total: ${overlayTriggers.length}');

      if (overlayTriggers.isEmpty) {
        debugPrint('⚠️ NO OVERLAY TRIGGERS SCHEDULED!');
        return;
      }

      for (var notification in overlayTriggers) {
        final content = notification.content;
        final schedule = notification.schedule;

        if (content != null) {
          final isSnooze = content.payload?['isSnooze'] == 'true';
          final isAlarm = content.channelKey == alarmChannelKey;
          final marker = isSnooze ? (isAlarm ? '🚨 ALARM' : '⏰ SNOOZE') : '📢 DAILY';
          debugPrint('  ✓ $marker - ID: ${content.id}, Prayer: ${content.payload?['prayerName']}');
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