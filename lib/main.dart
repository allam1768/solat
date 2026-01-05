import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:solat/page/home/HomeController.dart';
import 'package:solat/service/NotificationService.dart';
import 'package:solat/service/OverlaySchedulerService.dart';
import 'package:solat/service/OverlayService.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'core/app_theme.dart';
import 'overlay_entry.dart';
import 'routes/app_pages.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  // ✅ Initialize NotificationService
  await NotificationService().initialize();

  // ✅ Initialize OverlayScheduler channel
  await OverlaySchedulerService().initializeOverlayChannel();

  // 🔥 CRITICAL: Setup notification listeners
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: NotificationController.onActionReceivedMethod,
    onNotificationCreatedMethod: NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod: NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod: NotificationController.onDismissActionReceivedMethod,
  );

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

  runApp(const MyApp());
}

// 🔥 Notification Controller untuk handle notification events
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

    // 🔥 Check if this is an overlay trigger
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

    // Check if this is an overlay trigger
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

      debugPrint('🔥 Overlay trigger fired for: $prayerName');
      debugPrint('   Message: $message');
      debugPrint('   Next: $nextPrayerName $nextPrayerTime');

      final overlayService = OverlayService();

      // Show overlay with prayer data
      await overlayService.showPrayerOverlay(
        prayerName: prayerName,
        message: message,
        nextPrayerTime: '$nextPrayerName $nextPrayerTime',
        currentTime: DateTime.now().toString(),
      );
    } catch (e) {
      debugPrint('❌ Error handling overlay trigger: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
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
          themeMode: ThemeMode.light,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
// Di lib/main.dart
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized(); // Tambahkan ini
  runApp(const OverlayApp());
}