import 'package:get/get.dart';
import '../page/splash/SplashScreen.dart';
import '../page/splash/SplashBinding.dart';
import '../page/main/MainScreen.dart';
import '../page/main/MainBinding.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = AppRoutes.SPLASH;

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashScreen(),
      bindings: [
        SplashBinding(),
      ],
    ),

    GetPage(
      name: AppRoutes.MAIN,
      page: () => MainScreen(),
      bindings: [
        MainBinding(),
      ],
    ),

  ];
}