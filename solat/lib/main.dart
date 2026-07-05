import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:solat/service/location_service.dart';
import 'package:solat/service/prayer_time_service.dart';
import 'package:solat/service/notification_service.dart';
import 'package:solat/service/overlay_scheduler_service.dart';
import 'package:solat/service/update_service.dart';
import 'core/app_theme.dart';
import 'core/localization/app_translations.dart';
import 'routes/app_pages.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@pragma("vm:entry-point")
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Init storage dulu
  await GetStorage.init();

  // ✅ Initialize Global Services
  final notificationService = NotificationService();
  await notificationService.initialize();
  Get.put(notificationService);

  final overlayScheduler = OverlaySchedulerService();
  await overlayScheduler.initializeOverlayChannel();
  Get.put(overlayScheduler);

  Get.put(LocationService());
  Get.put(PrayerTimeService());
  Get.put(UpdateService());

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          translations: AppTranslations(),
          locale: Locale(storage.read('languageCode') ?? 'en', storage.read('countryCode') ?? 'US'),
          fallbackLocale: const Locale('en', 'US'),
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}