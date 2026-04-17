import 'package:get/get.dart';
import 'package:solat/page/qibla/QiblaController.dart';

class QiblaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QiblaController>(() => QiblaController());
  }
}