import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    print('SPLASH CONTROLLER ON INIT');
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    print('DELAY START');
    await Future.delayed(const Duration(seconds: 3));
    print('TRY NAVIGATE');
    Get.offNamed('/main');
  }
}
