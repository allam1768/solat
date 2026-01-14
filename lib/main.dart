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
  runApp(const OverlayApp());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Init storage dulu
  await GetStorage.init();

  // ✅ Initialize notification service (tanpa request permission)
  await NotificationService().initialize();

  // ✅ Initialize overlay channel (tanpa request permission)
  await OverlaySchedulerService().initializeOverlayChannel();

  // ✅ Setup notification listeners
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
  );

  // ✅ Setup overlay listener
  _setupOverlayDataListener();

  // ✅ Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ Setup system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

Future<void> _scheduleBackupSnoozes(String prayerName, String message, String nextPrayerName, String nextPrayerTime) async {
  try {
    final storage = GetStorage();
    final now = DateTime.now();
    final snoozeIds = <int>[];

    for (int i = 0; i < 2; i++) {
      final snoozeMinutes = 5;
      final triggerTime = now.add(Duration(minutes: (i + 1) * snoozeMinutes));
      final snoozeId = 200 + (prayerName.hashCode % 50) + i;

      snoozeIds.add(snoozeId);

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
            'attempt': '${i + 1}',
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

    await storage.write('backup_snooze_ids_$prayerName', snoozeIds);
  } catch (e, stack) {
    debugPrint('Error scheduling backup snoozes: $e');
    debugPrint('Stack: $stack');
  }
}

Future<void> _cancelBackupSnoozes(String prayerName) async {
  try {
    final storage = GetStorage();
    final snoozeIds = storage.read('backup_snooze_ids_$prayerName') as List<dynamic>?;

    if (snoozeIds == null || snoozeIds.isEmpty) return;

    for (final id in snoozeIds) {
      try {
        await AwesomeNotifications().cancel(id as int);
      } catch (e) {
        debugPrint('Failed to cancel snooze $id: $e');
      }
    }

    await storage.remove('backup_snooze_ids_$prayerName');
  } catch (e, stack) {
    debugPrint('Error cancelling backup snoozes: $e');
    debugPrint('Stack: $stack');
  }
}

void _setupOverlayDataListener() {
  FlutterOverlayWindow.overlayListener.listen((data) async {
    try {
      final action = data['action'];
      final prayerName = data['prayerName'];

      if (action == null || prayerName == null) {
        debugPrint('Invalid overlay data: $data');
        return;
      }

      final scheduler = OverlaySchedulerService();
      final overlayService = OverlayService();

      await Future.delayed(const Duration(milliseconds: 200));

      switch (action) {
        case 'prayer_done':
          await scheduler.handlePrayerDone(prayerName);
          await _cancelBackupSnoozes(prayerName);

          try {
            final isActive = await overlayService.isOverlayActive();
            if (isActive) {
              await FlutterOverlayWindow.closeOverlay().timeout(
                const Duration(milliseconds: 500),
                onTimeout: () => false,
              );
            }
          } catch (e) {
            debugPrint('Error closing overlay: $e');
          }
          break;

        default:
          debugPrint('Unknown action: $action');
      }
    } catch (e, stack) {
      debugPrint('Error in overlay listener: $e');
      debugPrint('Stack: $stack');

      try {
        await FlutterOverlayWindow.closeOverlay().timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => false,
        );
      } catch (_) {}
    }
  });
}

class NotificationController {
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    if (receivedNotification.title == 'prayer_done_signal') {
      final prayerName = receivedNotification.body ?? 'Unknown';
      await _handlePrayerDoneFromOverlay(prayerName);
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    if (receivedNotification.title == 'overlay_trigger') {
      await _handleOverlayTrigger(receivedNotification);
    }

    if (receivedNotification.title == 'prayer_done_signal') {
      final prayerName = receivedNotification.body ?? 'Unknown';
      await _handlePrayerDoneFromOverlay(prayerName);
    }
  }

  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // Silent dismiss
  }

  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.payload?['type'] == 'overlay_trigger') {
      await _handleOverlayTrigger(receivedAction);
    }

    if (receivedAction.payload?['type'] == 'prayer_done') {
      final prayerName = receivedAction.payload?['prayerName'] ?? 'Unknown';
      await _handlePrayerDoneFromOverlay(prayerName);
    }
  }

  static Future<void> _handlePrayerDoneFromOverlay(String prayerName) async {
    try {
      final scheduler = OverlaySchedulerService();

      await scheduler.handlePrayerDone(prayerName);
      await _cancelBackupSnoozes(prayerName);

      try {
        final overlayService = OverlayService();
        final isActive = await overlayService.isOverlayActive();
        if (isActive) {
          await FlutterOverlayWindow.closeOverlay().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () => false,
          );
        }
      } catch (e) {
        debugPrint('Overlay close error: $e');
      }
    } catch (e, stack) {
      debugPrint('Error handling prayer done: $e');
      debugPrint('Stack: $stack');
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
        debugPrint('No payload in notification');
        return;
      }

      final prayerName = payload['prayerName'] ?? 'Unknown';
      final message = payload['message'] ?? '';
      final nextPrayerName = payload['nextPrayerName'] ?? '';
      final nextPrayerTime = payload['nextPrayerTime'] ?? '';
      final isSnooze = payload['isSnooze'] == 'true';
      final attemptFromPayload = int.tryParse(payload['attempt'] ?? '0') ?? 0;

      final overlayService = OverlayService();

      if (!isSnooze) {
        await _scheduleBackupSnoozes(prayerName, message, nextPrayerName, nextPrayerTime);
      }

      await overlayService.showPrayerOverlay(
        prayerName: prayerName,
        message: message,
        nextPrayerTime: '$nextPrayerName $nextPrayerTime',
        currentTime: DateTime.now().toString(),
        forceAttempt: isSnooze ? attemptFromPayload : 0,
      );
    } catch (e, stack) {
      debugPrint('Error handling overlay trigger: $e');
      debugPrint('Stack: $stack');
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