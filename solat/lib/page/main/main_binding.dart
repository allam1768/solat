import 'package:get/get.dart';
import 'package:solat/page/qibla/qibla_controller.dart';
import 'main_controller.dart';
import '../home/home_controller.dart';
import '../settings/settings_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<SettingsController>(() => SettingsController());
    Get.lazyPut<QiblaController>(() => QiblaController());


  }
}