import 'package:get/get.dart';
import '../../service/OverlayService.dart';
import '../../service/NotificationService.dart';
import 'package:solat/page/home/HomeController.dart';

class SettingsController extends GetxController {
  final OverlayService _overlayService = OverlayService();
  final NotificationService _notificationService = NotificationService();

  // Observable states
  var notificationEnabled = true.obs; // BARU: Toggle untuk notifikasi ID 1-5
  var overlayDuration = 5.obs; // Durasi overlay (dalam menit)
  var hasOverlayPermission = false.obs;
  var isRequestingPermission = false.obs;

  // Duration options (in minutes)
  final List<int> durationOptions = [1, 3, 5, 10, 15, 30];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _checkOverlayPermission();
  }

  Future<void> _loadSettings() async {
    notificationEnabled.value = _notificationService.isNotificationEnabled();
    overlayDuration.value = _overlayService.getOverlayDuration();
  }

  Future<void> _checkOverlayPermission() async {
    final permission = await _overlayService.requestOverlayPermission();
    hasOverlayPermission.value = permission;
  }

  // BARU: Toggle notifikasi waktu sholat (ID 1-5)
  Future<void> toggleNotification(bool value) async {
    notificationEnabled.value = value;
    await _notificationService.setNotificationEnabled(value);

    // Re-schedule atau cancel notifikasi
    final homeController = Get.find<HomeController>();
    await homeController.refreshLocation(); // Akan trigger ulang scheduling

    Get.snackbar(
      'Pengaturan Disimpan',
      value ? 'Notifikasi waktu sholat diaktifkan' : 'Notifikasi waktu sholat dinonaktifkan',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Set durasi overlay
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

  // Request overlay permission
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

  // BARU: Test notifikasi
  Future<void> testNotification() async {
    if (!notificationEnabled.value) {
      Get.snackbar(
        'Notifikasi Nonaktif',
        'Aktifkan notifikasi terlebih dahulu',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    await _notificationService.showInstantNotification(
      title: '🕌 Test Notifikasi',
      body: 'Ini adalah notifikasi test. Notifikasi bekerja dengan baik!',
    );

    Get.snackbar(
      'Notifikasi Terkirim',
      'Cek panel notifikasi Anda',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }
}