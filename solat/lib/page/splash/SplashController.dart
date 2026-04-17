import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    final bool onboardingCompleted = _storage.read('onboarding_completed') ??
        false;

    if (onboardingCompleted) {
      Get.offNamed(AppRoutes.MAIN);
    } else {
      Get.offNamed(AppRoutes.ONBOARDING);
    }
  }
}