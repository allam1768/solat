import 'package:get/get.dart';
import '../../service/update_service.dart';

class MainController extends GetxController {
  // Observable untuk current index bottom nav
  var currentIndex = 0.obs;

  // Function untuk ganti tab
  void changeTab(int index) {
    currentIndex.value = index;
  }

  @override
  void onReady() {
    super.onReady();
    _checkForUpdates();
  }

  void _checkForUpdates() async {
    // delay check to let main screen render smoothly
    await Future.delayed(const Duration(seconds: 3));
    try {
      final updateService = Get.find<UpdateService>();
      await updateService.checkForUpdate(isManual: false);
    } catch (e) {
      // Ignore background check failure
    }
  }
}