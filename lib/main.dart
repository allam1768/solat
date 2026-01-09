import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:solat/page/home/HomeController.dart';
import 'package:solat/service/NotificationService.dart';
import 'package:solat/service/OverlaySchedulerService.dart';
import 'package:solat/service/OverlayService.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'core/app_theme.dart';
import 'overlay_entry.dart';
import 'routes/app_pages.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🎯 === OVERLAY ENTRY POINT CALLED ===');
  runApp(const OverlayApp());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 === APP STARTING ===');

  await GetStorage.init();
  debugPrint('✅ GetStorage initialized');

  await NotificationService().initialize();
  debugPrint('✅ NotificationService initialized');

  await OverlaySchedulerService().initializeOverlayChannel();
  debugPrint('✅ OverlayScheduler initialized');

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
  );
  debugPrint('✅ Notification listeners set');

  _setupOverlayDataListener();
  debugPrint('✅ Overlay data listener registered');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  debugPrint('🎉 === APP INITIALIZATION COMPLETE ===\n');
  runApp(const MyApp());
}

// ✅ Schedule backup snooze notifications (2 backup = 3 total overlay)
Future<void> _scheduleBackupSnoozes(String prayerName, String message, String nextPrayerName, String nextPrayerTime) async {
  try {
    final storage = GetStorage();
    final now = DateTime.now();

    debugPrint('📢 === SCHEDULING BACKUP SNOOZES ===');
    debugPrint('   Prayer: $prayerName');

    // ✅ Schedule 2 backup snoozes (overlay 2 dan 3)
    final snoozeIds = <int>[];

    for (int i = 0; i < 2; i++) {
      final snoozeMinutes = 5; // Semua jarak 5 menit
      final triggerTime = now.add(Duration(minutes: (i + 1) * snoozeMinutes)); // +5min, +10min
      final snoozeId = 200 + (prayerName.hashCode % 50) + i;

      snoozeIds.add(snoozeId);

      debugPrint('   📅 Backup snooze ${i + 2}: ${triggerTime.hour}:${triggerTime.minute.toString().padLeft(2, '0')} (ID: $snoozeId)');

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: snoozeId,
          channelKey: 'prayer_overlay_channel',
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
            'isSnooze': 'true',
            'attempt': '${i + 1}', // Attempt 1 (overlay 2), Attempt 2 (overlay 3 - CRITICAL)
          },
        ),
        schedule: NotificationCalendar(
          year: triggerTime.year,
          month: triggerTime.month,
          day: triggerTime.day,
          hour: triggerTime.hour,
          minute: triggerTime.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );
    }

    // ✅ Save scheduled snooze IDs to storage for cancellation
    await storage.write('backup_snooze_ids_$prayerName', snoozeIds);

    debugPrint('✅ Backup snoozes scheduled: ${snoozeIds.join(", ")}');
    debugPrint('✅ === BACKUP SNOOZES COMPLETE ===');

  } catch (e, stack) {
    debugPrint('❌ Error scheduling backup snoozes: $e');
    debugPrint('Stack: $stack');
  }
}

// ✅ Cancel backup snoozes when Done is pressed
Future<void> _cancelBackupSnoozes(String prayerName) async {
  try {
    final storage = GetStorage();
    final snoozeIds = storage.read('backup_snooze_ids_$prayerName') as List<dynamic>?;

    if (snoozeIds == null || snoozeIds.isEmpty) {
      debugPrint('ℹ️ No backup snoozes to cancel for $prayerName');
      return;
    }

    debugPrint('🗑️ === CANCELLING BACKUP SNOOZES ===');
    debugPrint('   Prayer: $prayerName');
    debugPrint('   IDs to cancel: ${snoozeIds.join(", ")}');

    int cancelledCount = 0;
    for (final id in snoozeIds) {
      try {
        await AwesomeNotifications().cancel(id as int);
        cancelledCount++;
        debugPrint('   ✅ Cancelled notification ID: $id');
      } catch (e) {
        debugPrint('   ⚠️ Failed to cancel ID $id: $e');
      }
    }

    // Remove from storage
    await storage.remove('backup_snooze_ids_$prayerName');

    debugPrint('✅ Cancelled $cancelledCount/${snoozeIds.length} backup snoozes');
    debugPrint('✅ === BACKUP SNOOZES CANCELLATION COMPLETE ===');

  } catch (e, stack) {
    debugPrint('❌ Error cancelling backup snoozes: $e');
    debugPrint('Stack: $stack');
  }
}

void _setupOverlayDataListener() {
  debugPrint('🎧 === OVERLAY DATA LISTENER REGISTERED ===');

  FlutterOverlayWindow.overlayListener.listen((data) async {
    try {
      debugPrint('📨 === RECEIVED DATA FROM OVERLAY ===');
      debugPrint('📦 Raw Data: $data');

      final action = data['action'];
      final prayerName = data['prayerName'];

      if (action == null || prayerName == null) {
        debugPrint('⚠️ Invalid data from overlay: $data');
        return;
      }

      debugPrint('🔥 Processing action: $action for prayer: $prayerName');

      final scheduler = OverlaySchedulerService();
      final overlayService = OverlayService();

      await Future.delayed(const Duration(milliseconds: 200));

      switch (action) {
        case 'prayer_done':
          debugPrint('✅ === HANDLING PRAYER DONE ===');

          // ✅ 1. Reset attempt counter
          await scheduler.handlePrayerDone(prayerName);

          // ✅ 2. Cancel ALL backup snoozes (ini yang penting!)
          await _cancelBackupSnoozes(prayerName);

          // ✅ 3. Close overlay if still active
          try {
            final isActive = await overlayService.isOverlayActive();
            if (isActive) {
              await FlutterOverlayWindow.closeOverlay().timeout(
                const Duration(milliseconds: 500),
                onTimeout: () => false,
              );
              debugPrint('✅ Overlay closed');
            }
          } catch (e) {
            debugPrint('⚠️ Error checking/closing overlay: $e');
          }

          debugPrint('✅ === PRAYER DONE COMPLETE ===');
          debugPrint('   - Attempts reset');
          debugPrint('   - Backup snoozes cancelled');
          debugPrint('   - Overlay closed');
          break;

        default:
          debugPrint('⚠️ Unknown action: $action');
      }

      debugPrint('✅ === DATA PROCESSING COMPLETE ===\n');
    } catch (e, stack) {
      debugPrint('❌ === ERROR IN OVERLAY LISTENER ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stack');

      try {
        await FlutterOverlayWindow.closeOverlay().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => false,
        );
      } catch (_) {
        debugPrint('⚠️ Could not close overlay in error handler');
      }
    }
  });

  debugPrint('✅ Overlay listener setup complete');
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('✅ Notification created: ${receivedNotification.id} - ${receivedNotification.title}');
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    debugPrint('✅ Notification displayed: ${receivedNotification.id} - ${receivedNotification.title}');

    if (receivedNotification.title == 'overlay_trigger') {
      debugPrint('🔥 Overlay trigger detected in displayed method');
      await _handleOverlayTrigger(receivedNotification);
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('⚠️ Notification dismissed: ${receivedAction.id}');
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    debugPrint('✅ Notification action received: ${receivedAction.id}');

    if (receivedAction.payload?['type'] == 'overlay_trigger') {
      debugPrint('🔥 Overlay trigger detected in action method');
      await _handleOverlayTrigger(receivedAction);
    }
  }

  static Future<void> _handleOverlayTrigger(dynamic notification) async {
    try {
      Map<String, String?>? payload;

      if (notification is ReceivedNotification) {
        payload = notification.payload;
      } else if (notification is ReceivedAction) {
        payload = notification.payload;
      }

      if (payload == null) {
        debugPrint('❌ No payload found in notification');
        return;
      }

      final prayerName = payload['prayerName'] ?? 'Unknown';
      final message = payload['message'] ?? '';
      final nextPrayerName = payload['nextPrayerName'] ?? '';
      final nextPrayerTime = payload['nextPrayerTime'] ?? '';
      final isSnooze = payload['isSnooze'] == 'true';

      // ✅ AMBIL ATTEMPT DARI PAYLOAD (untuk backup snooze)
      final attemptFromPayload = int.tryParse(payload['attempt'] ?? '0') ?? 0;

      debugPrint('🔥 === OVERLAY TRIGGER FIRED ===');
      debugPrint('   Prayer: $prayerName');
      debugPrint('   Message: $message');
      debugPrint('   Next: $nextPrayerName $nextPrayerTime');
      debugPrint('   Is Snooze: $isSnooze');
      debugPrint('   Attempt: $attemptFromPayload');

      final overlayService = OverlayService();

      // ✅ If NOT snooze (first trigger), schedule backup snoozes
      if (!isSnooze) {
        debugPrint('🎯 First trigger - scheduling backup snoozes');
        await _scheduleBackupSnoozes(prayerName, message, nextPrayerName, nextPrayerTime);
      }

      // ✅ GUNAKAN ATTEMPT DARI PAYLOAD untuk backup snooze
      await overlayService.showPrayerOverlay(
        prayerName: prayerName,
        message: message,
        nextPrayerTime: '$nextPrayerName $nextPrayerTime',
        currentTime: DateTime.now().toString(),
        forceAttempt: isSnooze ? attemptFromPayload : 0, // ✅ Force attempt dari payload
      );

      debugPrint('✅ === OVERLAY TRIGGER COMPLETE ===');
    } catch (e, stack) {
      debugPrint('❌ Error handling overlay trigger: $e');
      debugPrint('Stack trace: $stack');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());

    final storage = GetStorage();
    final isDarkTheme = storage.read('isDarkTheme') ?? false;

    return ScreenUtilInit(
      designSize: const Size(412, 917),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Solat App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}