import 'package:get/get.dart';
import '../../service/OverlayService.dart';

class SettingsController extends GetxController {
  final OverlayService _overlayService = OverlayService();

  // Observable states
  var overlayEnabled = true.obs;
  var overlayDuration = 5.obs; // dalam menit
  var isRequestingPermission = false.obs;
  var hasOverlayPermission = false.obs;

  // Duration options (in minutes)
  final List<int> durationOptions = [1, 3, 5, 10, 15, 30];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _checkOverlayPermission();
  }

  Future<void> _loadSettings() async {
    overlayEnabled.value = _overlayService.isOverlayEnabled();
    overlayDuration.value = _overlayService.getOverlayDuration();
  }

  Future<void> _checkOverlayPermission() async {
    final permission = await _overlayService.requestOverlayPermission();
    hasOverlayPermission.value = permission;
  }

  Future<void> toggleOverlay(bool value) async {
    if (value && !hasOverlayPermission.value) {
      await requestOverlayPermission();
      if (!hasOverlayPermission.value) {
        Get.snackbar(
          'Izin Diperlukan',
          'Aplikasi memerlukan izin overlay untuk menampilkan pengingat',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    overlayEnabled.value = value;
    await _overlayService.setOverlayEnabled(value);

    Get.snackbar(
      'Pengaturan Disimpan',
      value ? 'Overlay diaktifkan' : 'Overlay dinonaktifkan',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> setOverlayDuration(int minutes) async {
    overlayDuration.value = minutes;
    await _overlayService.setOverlayDuration(minutes);

    Get.snackbar(
      'Pengaturan Disimpan',
      'Durasi overlay diatur ke $minutes menit',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> requestOverlayPermission() async {
    isRequestingPermission.value = true;

    final granted = await _overlayService.requestOverlayPermission();
    hasOverlayPermission.value = granted;

    isRequestingPermission.value = false;

    if (!granted) {
      Get.snackbar(
        'Izin Ditolak',
        'Silakan aktifkan izin overlay di pengaturan sistem',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Test overlay manually
  Future<void> testOverlay() async {
    if (!overlayEnabled.value) {
      Get.snackbar(
        'Overlay Nonaktif',
        'Aktifkan overlay terlebih dahulu di pengaturan',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (!hasOverlayPermission.value) {
      Get.snackbar(
        'Izin Diperlukan',
        'Berikan izin overlay terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    Get.snackbar(
      'Testing Overlay',
      'Overlay akan muncul dalam 2 detik...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    await Future.delayed(const Duration(seconds: 2));

    await _overlayService.showPrayerOverlay(
      prayerName: 'Test Prayer',
      message: 'Ini adalah test overlay.\nOverlay berhasil ditampilkan!',
      nextPrayerTime: 'Dzuhur 12:00',
      currentTime: DateTime.now().toString(),
    );
  }
}