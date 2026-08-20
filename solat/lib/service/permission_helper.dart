import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:solat/core/widgets/app_button.dart';
import 'dart:io';
import 'overlay_service.dart';

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
        'xiaomi',
        'redmi',
        'poco',
        'oppo',
        'realme',
        'oneplus',
        'vivo',
        'iqoo',
        'huawei',
        'honor',
        'samsung'
      ];

      final isProblematic =
          problematicOEMs.any((oem) => manufacturer.contains(oem));

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

  // Check all critical permissions (Location, Notification, Overlay)
  Future<ph.PermissionStatus> checkAllPermissions() async {
    try {
      final locationStatus = await ph.Permission.location.status;
      final notificationStatus = await ph.Permission.notification.status;
      final overlayStatus = await ph.Permission.systemAlertWindow.status;
      final overlayWindowGranted = await OverlayService().hasOverlayPermission();

      final isLocationGranted = locationStatus.isGranted;
      final isNotificationGranted = notificationStatus.isGranted;
      final isOverlayGranted = overlayStatus.isGranted || overlayWindowGranted;

      // All 3 critical permissions (Location, Notification, Overlay) must be granted!
      if (isLocationGranted && isNotificationGranted && isOverlayGranted) {
        return ph.PermissionStatus.granted;
      }

      return ph.PermissionStatus.denied;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return ph.PermissionStatus.denied;
    }
  }

  // Request all necessary permissions
  Future<bool> requestAllPermissions() async {
    await ph.Permission.location.request();
    await ph.Permission.notification.request();
    await ph.Permission.systemAlertWindow.request();
    await ph.Permission.scheduleExactAlarm.request();

    final status = await checkAllPermissions();
    return status == ph.PermissionStatus.granted;
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
      fullMessage +=
          '\n\n⚠️ Perangkat ${oemInfo.manufacturer.toUpperCase()} Terdeteksi:\n$oemSpecificMessage';
    }

    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20.sp,
              ),
            ),
            content: SingleChildScrollView(
              child: Text(
                fullMessage,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              ),
            ),
            actionsPadding:
                EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      text: 'nanti aja',
                      onTap: () => Get.back(result: false),
                      height: 48.h,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      borderRadius: 30.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton.filled(
                      text: 'lanjut',
                      onTap: () => Get.back(result: true),
                      height: 48.h,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      borderRadius: 30.r,
                    ),
                  ),
                ],
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
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

  String get deviceName =>
      model != null ? '$manufacturer $model' : manufacturer;

  String get oemGuidance {
    final mfr = manufacturer.toLowerCase();

    if (mfr.contains('xiaomi') ||
        mfr.contains('redmi') ||
        mfr.contains('poco')) {
      return '''
Pengaturan Xiaomi/MIUI:
1. Pengaturan → Aplikasi → Kelola Aplikasi → Solat
2. Mulai otomatis (Autostart) → Aktifkan
3. Penghemat baterai → Tanpa pembatasan
4. Izin lainnya → Tampilkan jendela pop-up → Aktifkan
5. Notifikasi → Aktifkan semua
''';
    } else if (mfr.contains('oppo') || mfr.contains('realme')) {
      return '''
Pengaturan Oppo/Realme:
1. Pengaturan → Baterai → Penggunaan Latar Belakang Tinggi → Aktifkan
2. Pengaturan → Aplikasi → Solat → Izinkan "Tampil di atas aplikasi lain"
3. Pengaturan → Privasi → Manajer Mulai → Aktifkan Solat
''';
    } else if (mfr.contains('vivo')) {
      return '''
Pengaturan Vivo:
1. Pengaturan → Baterai → Pengelolaan Konsumsi Baterai Latar Belakang → Solat → Tinggi
2. Pengaturan → Pengaturan Lainnya → Manajer Izin → Mulai Otomatis → Aktifkan
''';
    } else if (mfr.contains('samsung')) {
      return '''
Pengaturan Samsung:
1. Pengaturan → Baterai → Batas penggunaan latar belakang → Aplikasi yang tidak pernah tidur → Tambahkan Solat
2. Pengaturan → Aplikasi → Solat → Baterai → Tidak dibatasi
''';
    } else if (mfr.contains('huawei') || mfr.contains('honor')) {
      return '''
Pengaturan Huawei/Honor:
1. Pengaturan → Aplikasi → Solat → Baterai → Izinkan "Jalan di latar belakang"
2. Pengaturan → Baterai → Peluncuran Aplikasi → Solat → Kelola secara manual (aktifkan semua)
''';
    }

    return 'Ikuti pengaturan izin standar Android.';
  }
}
