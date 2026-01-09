import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionHelper {
  static final PermissionHelper _instance = PermissionHelper._internal();
  factory PermissionHelper() => _instance;
  PermissionHelper._internal();

  // Check if device is from problematic OEM
  Future<OEMInfo> getOEMInfo() async {
    if (!Platform.isAndroid) {
      return OEMInfo(manufacturer: 'Unknown', isProblematic: false);
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final manufacturer = androidInfo.manufacturer.toLowerCase();

      final problematicOEMs = [
        'xiaomi', 'redmi', 'poco',
        'oppo', 'realme', 'oneplus',
        'vivo', 'iqoo',
        'huawei', 'honor',
        'samsung' // Samsung juga agak strict
      ];

      final isProblematic = problematicOEMs.any((oem) => manufacturer.contains(oem));

      return OEMInfo(
        manufacturer: androidInfo.manufacturer,
        model: androidInfo.model,
        androidVersion: androidInfo.version.release,
        sdkInt: androidInfo.version.sdkInt,
        isProblematic: isProblematic,
      );
    } catch (e) {
      debugPrint('Error getting OEM info: $e');
      return OEMInfo(manufacturer: 'Unknown', isProblematic: false);
    }
  }

  // Check all critical permissions
  Future<PermissionStatus> checkAllPermissions() async {
    final results = {
      'notification': await Permission.notification.status,
      'overlay': await Permission.systemAlertWindow.status,
      'scheduleExactAlarm': await Permission.scheduleExactAlarm.status,
      'ignoreBatteryOptimizations': await Permission.ignoreBatteryOptimizations.status,
    };

    debugPrint('📋 Permission Status:');
    results.forEach((key, value) {
      debugPrint('   $key: ${value.isGranted ? "✅" : "❌"} $value');
    });

    // If any critical permission is denied, return denied
    if (!results['notification']!.isGranted ||
        !results['overlay']!.isGranted ||
        !results['scheduleExactAlarm']!.isGranted) {
      return PermissionStatus.denied;
    }

    return PermissionStatus.granted;
  }

  // Request all necessary permissions
  Future<bool> requestAllPermissions() async {
    debugPrint('🔐 === REQUESTING ALL PERMISSIONS ===');

    // 1. Notification Permission
    var notificationStatus = await Permission.notification.request();
    debugPrint('   Notification: ${notificationStatus.isGranted ? "✅" : "❌"}');

    // 2. Overlay Permission
    var overlayStatus = await Permission.systemAlertWindow.request();
    debugPrint('   Overlay: ${overlayStatus.isGranted ? "✅" : "❌"}');

    // 3. Schedule Exact Alarm (Android 12+)
    var alarmStatus = await Permission.scheduleExactAlarm.request();
    debugPrint('   Exact Alarm: ${alarmStatus.isGranted ? "✅" : "❌"}');

    // 4. Battery Optimization (optional but recommended)
    var batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      debugPrint('   Battery Optimization: ⚠️ Not disabled (optional)');
    }

    final allGranted = notificationStatus.isGranted &&
        overlayStatus.isGranted &&
        alarmStatus.isGranted;

    debugPrint(allGranted ? '✅ All critical permissions granted' : '❌ Some permissions missing');

    return allGranted;
  }

  // Request battery optimization exemption
  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;

      if (status.isGranted) {
        debugPrint('✅ Battery optimization already disabled');
        return true;
      }

      final result = await Permission.ignoreBatteryOptimizations.request();

      if (result.isGranted) {
        debugPrint('✅ Battery optimization disabled');
        return true;
      } else {
        debugPrint('❌ Battery optimization request denied');
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting battery exemption: $e');
      return false;
    }
  }

  // Show permission dialog with explanation
  Future<bool> showPermissionDialog({
    required String title,
    required String message,
    String? oemSpecificMessage,
  }) async {
    final oemInfo = await getOEMInfo();

    String fullMessage = message;

    if (oemInfo.isProblematic && oemSpecificMessage != null) {
      fullMessage += '\n\n⚠️ ${oemInfo.manufacturer.toUpperCase()} Device Detected:\n$oemSpecificMessage';
    }

    return await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(fullMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Continue'),
          ),
        ],
      ),
      barrierDismissible: false,
    ) ?? false;
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

// OEM Info Model
class OEMInfo {
  final String manufacturer;
  final String? model;
  final String? androidVersion;
  final int? sdkInt;
  final bool isProblematic;

  OEMInfo({
    required this.manufacturer,
    this.model,
    this.androidVersion,
    this.sdkInt,
    required this.isProblematic,
  });

  String get deviceName => model != null ? '$manufacturer $model' : manufacturer;

  String get oemGuidance {
    final mfr = manufacturer.toLowerCase();

    if (mfr.contains('xiaomi') || mfr.contains('redmi') || mfr.contains('poco')) {
      return '''
Xiaomi/MIUI Settings:
1. Settings → Apps → Manage Apps → Solat
2. Autostart → Enable
3. Battery Saver → No restrictions
4. Other permissions → Display pop-up windows → Enable
5. Notifications → Enable all
''';
    } else if (mfr.contains('oppo') || mfr.contains('realme')) {
      return '''
Oppo/Realme Settings:
1. Settings → Battery → High Background Consumption → Enable
2. Settings → Apps → Solat → Allow "Display over other apps"
3. Settings → Privacy → Startup Manager → Enable Solat
''';
    } else if (mfr.contains('vivo')) {
      return '''
Vivo Settings:
1. Settings → Battery → Background Battery Consumption Management → Solat → High
2. Settings → More Settings → Permission Management → Autostart → Enable
''';
    } else if (mfr.contains('samsung')) {
      return '''
Samsung Settings:
1. Settings → Battery → Background usage limits → Never sleeping apps → Add Solat
2. Settings → Apps → Solat → Battery → Unrestricted
''';
    } else if (mfr.contains('huawei') || mfr.contains('honor')) {
      return '''
Huawei/Honor Settings:
1. Settings → Apps → Solat → Battery → Enable "Run in background"
2. Settings → Battery → App Launch → Solat → Manage manually (enable all)
''';
    }

    return 'Follow standard Android permission settings.';
  }
}