import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/overlay_service.dart';
import '../../service/notification_service.dart';
import '../../service/permission_helper.dart'; // ✅ NEW
import '../../service/update_service.dart'; // ✅ NEW
import 'package:solat/page/home/home_controller.dart';

class SettingsController extends GetxController with WidgetsBindingObserver {
  final OverlayService _overlayService = OverlayService();
  final NotificationService _notificationService = NotificationService();
  final PermissionHelper _permissionHelper = PermissionHelper(); // ✅ NEW
  final UpdateService _updateService = Get.find<UpdateService>(); // ✅ NEW
  final _storage = GetStorage();

  var notificationEnabled = true.obs;
  var hasOverlayPermission = false.obs;
  var hasFullScreenPermission = false.obs; // ✅ NEW
  var isRequestingPermission = false.obs;
  var isDarkTheme = false.obs;
  var fridayReminderEnabled = true.obs; // NEW
  var reminderProfile = 1.obs; // Default to SMART (1)
  var languageCode = 'en'.obs;
  var testAttempt = 0.obs;
  Timer? _debounceTimer; // NEW: Debounce for anti-spam

  // ✅ OEM Info
  var deviceManufacturer = 'Unknown'.obs;
  var isProblematicDevice = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _checkAllPermissions();
    _loadDeviceInfo();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 SettingsController: App resumed, checking permissions...');
      _checkAllPermissions();
    }
  }

  Future<void> _loadSettings() async {
    notificationEnabled.value = _notificationService.isNotificationEnabled();
    isDarkTheme.value = _storage.read('isDarkTheme') ?? false;
    fridayReminderEnabled.value =
        _storage.read(NotificationService.fridayReminderEnabledKey) ?? true;
    reminderProfile.value = _storage.read('reminderProfile') ?? 1;
    languageCode.value = _storage.read('languageCode') ?? 'en';
  }

  // ✅ Check all permissions
  Future<void> _checkAllPermissions() async {
    try {
      final status = await _permissionHelper.checkAllPermissions();
      final isGranted = status == PermissionStatus.granted;
      hasOverlayPermission.value = isGranted;
    } catch (e) {
      hasOverlayPermission.value = false;
    }
  }

  // âœ… Load device info
  // ✅ Load device info
  Future<void> _loadDeviceInfo() async {
    final oemInfo = await _permissionHelper.getOEMInfo();
    deviceManufacturer.value = oemInfo.deviceName;
    isProblematicDevice.value = oemInfo.isProblematic;

    if (oemInfo.isProblematic) {
      debugPrint('⚠️ Problematic device detected: ${oemInfo.manufacturer}');
    }
  }

  // ✅ Anti-Spam Debounce Helper
  void _debouncedRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1500), () async {
      debugPrint('⚛️ Executing debounced background refresh...');
      try {
        final homeController = Get.find<HomeController>();
        await homeController.refreshLocation();
      } catch (e) {
        debugPrint('HomeController not found during refresh: $e');
      }
    });
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.grey.shade700,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> toggleNotification(bool value) async {
    notificationEnabled.value = value;
    await _notificationService.setNotificationEnabled(value);
    _debouncedRefresh();
  }

  Future<void> toggleFridayReminder(bool value) async {
    fridayReminderEnabled.value = value;
    await _storage.write(NotificationService.fridayReminderEnabledKey, value);
    _debouncedRefresh();
  }

  Future<void> toggleTheme(bool value) async {
    isDarkTheme.value = value;
    await _storage.write('isDarkTheme', value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setReminderProfile(int index) async {
    if (reminderProfile.value == index) return;

    reminderProfile.value = index;
    await _storage.write('reminderProfile', index);
    _debouncedRefresh();
  }

  Future<void> changeLanguage(String langCode, String countryCode) async {
    languageCode.value = langCode;
    await _storage.write('languageCode', langCode);
    await _storage.write('countryCode', countryCode);

    Get.updateLocale(Locale(langCode, countryCode));
  }

  // ✅ Request all critical permissions
  Future<void> requestAllPermissions() async {
    if (isRequestingPermission.value) return;
    isRequestingPermission.value = true;

    // Show explanation dialog
    final proceed = await _permissionHelper.showPermissionDialog(
      title: 'perlu izin tambahan',
      message: '''
Aplikasi butuh izin ini biar pengingat kamu jalan lancar:

1. Lokasi
   - Menentukan jadwal sholat yang akurat sesuai lokasi kamu

2. Tampil di atas aplikasi lain
   - Menampilkan pengingat sholat di layar

3. Notifikasi
   - Mengingatkan kamu saat masuk waktu sholat

4. Alarm presisi
   - Memastikan pengingat muncul tepat waktu

Tap lanjut buat ngatur izin ya.
      ''',
      oemSpecificMessage: isProblematicDevice.value
          ? 'perangkat kamu mungkin butuh pengaturan tambahan.'
          : null,
    );

    if (!proceed) {
      isRequestingPermission.value = false;
      return;
    }

    // Request permissions
    final granted = await _permissionHelper.requestAllPermissions();

    // Refresh status
    await _checkAllPermissions();

    isRequestingPermission.value = false;

    if (granted) {
      showToast('semua izin berhasil diaktifkan!');

      // Show OEM-specific guidance if needed
      if (isProblematicDevice.value) {
        await _showOEMGuidance();
      }
    } else {
      showToast('beberapa izin belum aktif');

      // Show what's missing
      await Get.dialog(
        AlertDialog(
          title: const Text('izin belum lengkap'),
          content: const Text(
              'beberapa izin belum diaktifkan. aplikasi mungkin nggak jalan lancar saat ditutup.\n\n'
              'kamu bisa mengizinkannya secara manual di pengaturan.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('nanti aja'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _permissionHelper.openAppSettings();
              },
              child: const Text('buka pengaturan'),
            ),
          ],
        ),
      );
    }
  }

  // ✅ Request overlay permission (legacy)
  Future<void> requestOverlayPermission() async {
    isRequestingPermission.value = true;

    final granted = await _overlayService.requestOverlayPermission();
    hasOverlayPermission.value = granted;

    isRequestingPermission.value = false;

    showToast(
        granted ? 'izin overlay diizinkan' : 'izin overlay ditolak');
  }

  // ✅ Show OEM-specific guidance
  Future<void> _showOEMGuidance() async {
    final oemInfo = await _permissionHelper.getOEMInfo();

    if (!oemInfo.isProblematic) return;

    await Get.dialog(
      AlertDialog(
        title: Text('Pengaturan ${oemInfo.manufacturer}'),
        content: SingleChildScrollView(
          child: Text(
            '⚠️ Penting: perangkat ${oemInfo.manufacturer} butuh pengaturan tambahan:\n\n'
            '${oemInfo.oemGuidance}\n\n'
            'Tanpa pengaturan ini, pengingat mungkin nggak muncul saat aplikasi ditutup.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('paham'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _permissionHelper.openAppSettings();
            },
            child: const Text('buka pengaturan'),
          ),
        ],
      ),
    );
  }

  // ✅ Show permission status
  Future<void> showPermissionStatus() async {
    final status = await _permissionHelper.checkAllPermissions();
    final oemInfo = await _permissionHelper.getOEMInfo();

    String statusText = 'Status Izin:\n\n';
    statusText += 'Overlay: ${hasOverlayPermission.value ? "✓" : "×"}\n';
    statusText += 'Notifikasi: ${notificationEnabled.value ? "✓" : "×"}\n';
    statusText += '\nPerangkat: ${oemInfo.deviceName}\n';

    if (oemInfo.isProblematic) {
      statusText += '\n⚠️ Perangkat ini mungkin butuh pengaturan tambahan.';
    }

    Get.dialog(
      AlertDialog(
        title: const Text('status izin'),
        content: Text(statusText),
        actions: [
          if (status != PermissionStatus.granted)
            ElevatedButton(
              onPressed: () {
                Get.back();
                requestAllPermissions();
              },
              child: const Text('perbaiki izin'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> resetPrayerAttempt(String prayerName) async {
    await _overlayService.resetAttempt(prayerName);
    showToast('percobaan direset buat $prayerName');
  }

  Future<void> launchFeedback() async {
    final Uri url = Uri.parse('https://forms.gle/eSCzoRJkqQ84CVrn8');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      showToast('gagal membuka formulir masukan');
    }
  }

  Future<void> checkManualUpdate() async {
    await _updateService.checkForUpdate(isManual: true);
  }

  String get appVersion => UpdateService.appVersion;
}
