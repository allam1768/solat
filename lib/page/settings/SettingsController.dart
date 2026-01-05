import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../service/OverlayService.dart';
import '../../service/NotificationService.dart';
import 'package:solat/page/home/HomeController.dart';
import 'package:flutter/material.dart';

class SettingsController extends GetxController {
  final OverlayService _overlayService = OverlayService();
  final NotificationService _notificationService = NotificationService();
  final _storage = GetStorage();

  // Observable states
  var notificationEnabled = true.obs;
  var overlayDuration = 5.obs; // Durasi overlay (dalam menit)
  var hasOverlayPermission = false.obs;
  var isRequestingPermission = false.obs;
  var isDarkTheme = false.obs;
  var selectedLanguage = 'ENG'.obs;

  // Duration options (in minutes)
  final List<int> durationOptions = [1, 3, 5, 10, 15, 30];
  final List<String> languages = ['ENG', 'IND'];

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _checkOverlayPermission();
  }

  Future<void> _loadSettings() async {
    notificationEnabled.value = _notificationService.isNotificationEnabled();
    overlayDuration.value = _overlayService.getOverlayDuration();
    isDarkTheme.value = _storage.read('isDarkTheme') ?? false;
    selectedLanguage.value = _storage.read('language') ?? 'ENG';
  }

  Future<void> _checkOverlayPermission() async {
    final permission = await _overlayService.requestOverlayPermission();
    hasOverlayPermission.value = permission;
  }

  // Toggle notifikasi waktu sholat (ID 1-5)
  Future<void> toggleNotification(bool value) async {
    notificationEnabled.value = value;
    await _notificationService.setNotificationEnabled(value);

    // Re-schedule atau cancel notifikasi
    try {
      final homeController = Get.find<HomeController>();
      await homeController.refreshLocation();
    } catch (e) {
      debugPrint('HomeController not found: $e');
    }

    Get.snackbar(
      'Settings Saved',
      value ? 'Prayer notifications enabled' : 'Prayer notifications disabled',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  // Increment duration
  void incrementDuration() {
    int currentIndex = durationOptions.indexOf(overlayDuration.value);
    if (currentIndex < durationOptions.length - 1) {
      setOverlayDuration(durationOptions[currentIndex + 1]);
    }
  }

  // Decrement duration
  void decrementDuration() {
    int currentIndex = durationOptions.indexOf(overlayDuration.value);
    if (currentIndex > 0) {
      setOverlayDuration(durationOptions[currentIndex - 1]);
    }
  }

  // Set durasi overlay
  Future<void> setOverlayDuration(int minutes) async {
    overlayDuration.value = minutes;
    await _overlayService.setOverlayDuration(minutes);

    Get.snackbar(
      'Settings Saved',
      'Overlay duration set to $minutes minutes',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  // Toggle theme
  Future<void> toggleTheme(bool value) async {
    isDarkTheme.value = value;
    await _storage.write('isDarkTheme', value);

    // Update theme mode
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);


  }

  // Change language
  Future<void> changeLanguage(String language) async {
    selectedLanguage.value = language;
    await _storage.write('language', language);

    // Update locale based on language
    Locale locale;
    switch (language) {
      case 'IND':
        locale = const Locale('id', 'ID');
        break;
      default:
        locale = const Locale('en', 'US');
    }
    Get.updateLocale(locale);

    Get.snackbar(
      'Language Changed',
      'Language set to $language',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
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
        'Permission Denied',
        'Please enable overlay permission in system settings',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    }
  }

  // Test overlay manually
  Future<void> testOverlay() async {
    if (!hasOverlayPermission.value) {
      Get.snackbar(
        'Permission Required',
        'Grant overlay permission first',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      return;
    }

    Get.snackbar(
      'Testing Overlay',
      'Overlay will appear in 2 seconds...',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );

    await Future.delayed(const Duration(seconds: 2));

    await _overlayService.showPrayerOverlay(
      prayerName: 'Test Prayer',
      message: 'This is a test overlay.\nOverlay displayed successfully!',
      nextPrayerTime: 'Dzuhur 12:00',
      currentTime: DateTime.now().toString(),
    );
  }

  // Test notifikasi
  Future<void> testNotification() async {
    if (!notificationEnabled.value) {
      Get.snackbar(
        'Notifications Disabled',
        'Enable notifications first',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      return;
    }

    await _notificationService.showInstantNotification(
      title: '🕌 Test Notification',
      body: 'This is a test notification. Notifications are working!',
    );

    Get.snackbar(
      'Notification Sent',
      'Check your notification panel',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }
}