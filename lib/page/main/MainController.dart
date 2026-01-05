import 'package:get/get.dart';

class MainController extends GetxController {
  // Observable untuk current index bottom nav
  var currentIndex = 0.obs;

  // Function untuk ganti tab
  void changeTab(int index) {
    currentIndex.value = index;
  }
}