import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:solat/page/home/HomeController.dart';
import 'package:solat/service/NotificationService.dart';
import 'package:solat/service/OverlaySchedulerService.dart';
import 'core/app_theme.dart';
import 'routes/app_pages.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@pragma("vm:entry-point")

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Init storage dulu
  await GetStorage.init();

  // ✅ Initialize notification service (tanpa request permission)
  await NotificationService().initialize();

  // ✅ Initialize overlay channel (tanpa request permission)
  await OverlaySchedulerService().initializeOverlayChannel();


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