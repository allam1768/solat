import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../service/OverlayService.dart';
import '../../service/NotificationService.dart';
import '../../service/PermissionHelper.dart'; // âœ… NEW
import 'package:solat/page/home/HomeController.dart';

class SettingsController extends GetxController {
  final OverlayService _overlayService = OverlayService();
  final NotificationService _notificationService = NotificationService();
  final PermissionHelper _permissionHelper = PermissionHelper(); // âœ… NEW
  final _storage = GetStorage();

  var notificationEnabled = true.obs;
  var hasOverlayPermission = false.obs;
  var hasFullScreenPermission = false.obs; // âœ… NEW
  var hasBatteryExemption = false.obs; // âœ… NEW
  var isRequestingPermission = false.obs;
  var isDarkTheme = false.obs;
  var testAttempt = 0.obs;

  // âœ… OEM Info
  var deviceManufacturer = 'Unknown'.obs;
  var isProblematicDevice = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _checkAllPermissions();
    _loadDeviceInfo();
  }

  Future<void> _loadSettings() async {
    notificationEnabled.value = _notificationService.isNotificationEnabled();
    isDarkTheme.value = _storage.read('isDarkTheme') ?? false;
  }

  // âœ… Check all permissions
  Future<void> _checkAllPermissions() async {
    try {
      final permission = await _overlayService.hasOverlayPermission();
      hasOverlayPermission.value = permission;

      // Check battery exemption
      final batteryStatus = await _permissionHelper.checkAllPermissions();
      hasBatteryExemption.value = batteryStatus == PermissionStatus.granted;

    } catch (e) {
      hasOverlayPermission.value = false;
      hasBatteryExemption.value = false;
    }
  }

  // âœ… Load device info
  Future<void> _loadDeviceInfo() async {
    final oemInfo = await _permissionHelper.getOEMInfo();
    deviceManufacturer.value = oemInfo.deviceName;
    isProblematicDevice.value = oemInfo.isProblematic;

    if (oemInfo.isProblematic) {
      debugPrint('âš ï¸ Problematic device detected: ${oemInfo.manufacturer}');
    }
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

    try {
      final homeController = Get.find<HomeController>();
      await homeController.refreshLocation();
    } catch (e) {
      debugPrint('HomeController not found: $e');
    }

    showToast(value ? 'Prayer notifications enabled' : 'Prayer notifications disabled');
  }

  Future<void> toggleTheme(bool value) async {
    isDarkTheme.value = value;
    await _storage.write('isDarkTheme', value);
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    showToast(value ? 'Dark theme enabled' : 'Light theme enabled');
  }

  // âœ… Request all critical permissions
  Future<void> requestAllPermissions() async {
    isRequestingPermission.value = true;

    // Show explanation dialog
    final proceed = await _permissionHelper.showPermissionDialog(
      title: 'Required Permissions',
      message: '''
This app needs the following permissions to work properly:

1. ðŸ“± Display over other apps
   - Show prayer time overlay

2. ðŸ”” Notifications
   - Alert you at prayer times

3. â° Exact alarms
   - Trigger reminders precisely

4. ðŸ”‹ Battery optimization exemption
   - Ensure reminders work even when app is closed

Tap Continue to grant these permissions.
      ''',
      oemSpecificMessage: isProblematicDevice.value
          ? 'Additional settings may be required for your device.'
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
      showToast('âœ… All permissions granted!');

      // Show OEM-specific guidance if needed
      if (isProblematicDevice.value) {
        await _showOEMGuidance();
      }
    } else {
      showToast('âš ï¸ Some permissions missing');

      // Show what's missing
      await Get.dialog(
        AlertDialog(
          title: const Text('Setup Incomplete'),
          content: const Text(
              'Some permissions were not granted. The app may not work properly when closed.\n\n'
                  'You can grant them manually in Settings.'
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _permissionHelper.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }
  }

  // âœ… Request overlay permission (legacy)
  Future<void> requestOverlayPermission() async {
    isRequestingPermission.value = true;

    final granted = await _overlayService.requestOverlayPermission();
    hasOverlayPermission.value = granted;

    isRequestingPermission.value = false;

    showToast(granted ? 'Overlay permission granted' : 'Overlay permission denied');
  }

  // âœ… Request battery exemption
  Future<void> requestBatteryExemption() async {
    final granted = await _permissionHelper.requestBatteryOptimizationExemption();
    hasBatteryExemption.value = granted;

    showToast(granted
        ? 'âœ… Battery optimization disabled'
        : 'âŒ Battery exemption denied');
  }

  // âœ… Show OEM-specific guidance
  Future<void> _showOEMGuidance() async {
    final oemInfo = await _permissionHelper.getOEMInfo();

    if (!oemInfo.isProblematic) return;

    await Get.dialog(
      AlertDialog(
        title: Text('${oemInfo.manufacturer} Setup'),
        content: SingleChildScrollView(
          child: Text(
            'âš ï¸ Important: ${oemInfo.manufacturer} devices require additional settings:\n\n'
                '${oemInfo.oemGuidance}\n\n'
                'Without these settings, reminders may not work when the app is closed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('I Understand'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _permissionHelper.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // âœ… Show permission status
  Future<void> showPermissionStatus() async {
    final status = await _permissionHelper.checkAllPermissions();
    final oemInfo = await _permissionHelper.getOEMInfo();

    String statusText = 'Permission Status:\n\n';
    statusText += 'Overlay: ${hasOverlayPermission.value ? "âœ“" : "Ã—"}\n';
    statusText += 'Notifications: ${notificationEnabled.value ? "âœ“" : "Ã—"}\n';
    statusText += 'Battery Exemption: ${hasBatteryExemption.value ? "âœ“" : "Ã—"}\n';
    statusText += '\nDevice: ${oemInfo.deviceName}\n';

    if (oemInfo.isProblematic) {
      statusText += '\nâš ï¸ This device may require additional settings.';
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Permission Status'),
        content: Text(statusText),
        actions: [
          if (status != PermissionStatus.granted)
            ElevatedButton(
              onPressed: () {
                Get.back();
                requestAllPermissions();
              },
              child: const Text('Fix Permissions'),
            ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  Future<void> resetPrayerAttempt(String prayerName) async {
    await _overlayService.resetAttempt(prayerName);
    showToast('Attempts reset for $prayerName');
  }

}