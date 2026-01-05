import 'package:get/get.dart';
import 'MainController.dart';
import '../home/HomeController.dart';
import '../settings/SettingsController.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<SettingsController>(() => SettingsController());
  }
}