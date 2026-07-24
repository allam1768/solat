// ignore_for_file: constant_identifier_names
import 'package:get/get.dart';
import 'package:solat/page/onboarding/onboarding_binding.dart';
import 'package:solat/page/onboarding/onboarding_screen.dart';
import '../page/splash/splash_screen.dart';
import '../page/splash/splash_binding.dart';
import '../page/main/main_screen.dart';
import '../page/main/main_binding.dart';
import '../page/privacy_policy/privacy_policy_screen.dart';
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

    GetPage(
      name: AppRoutes.ONBOARDING,
      page: () => OnboardingScreen(),
      bindings: [
        OnboardingBinding(),
      ],
    ),

    GetPage(
      name: AppRoutes.PRIVACY_POLICY,
      page: () => const PrivacyPolicyScreen(),
      transition: Transition.cupertino,
    ),
  ];
}