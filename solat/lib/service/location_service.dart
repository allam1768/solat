import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/widgets/app_button.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final String cityName;
  final String provinceName;
  final String isoCountryCode;
  final String errorMessage;
  final bool hasError;

  LocationResult({
    this.latitude,
    this.longitude,
    this.cityName = '',
    this.provinceName = '',
    this.isoCountryCode = '',
    this.errorMessage = '',
    this.hasError = false,
  });
}

class LocationService extends GetxService {
  bool _hasShownDialog = false;

  Future<LocationResult> getCurrentLocation({bool silent = true}) async {
    try {
      if (!silent) {
        _hasShownDialog = false;
      }
      // ✅ Khusus Web/Desktop (Linux/Windows/macOS): Pakai default location agar tidak error missing plugin
      if (kIsWeb || (!kIsWeb && !Platform.isAndroid && !Platform.isIOS)) {
        return LocationResult(
          latitude: -6.2088,
          longitude: 106.8456,
          cityName: 'Jakarta Selatan',
          provinceName: 'DKI Jakarta',
          isoCountryCode: 'ID',
          hasError: false,
        );
      }

      // ✅ Android / iOS Native: Pakai real GPS & Geocoding 100%
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && !_hasShownDialog) {
          _showGPSDialog();
        }
        return LocationResult(
          hasError: true,
          errorMessage: 'lokasi belum aktif',
          cityName: 'lokasi mati',
          provinceName: 'tap buat nyalain',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!silent && !_hasShownDialog) {
          _showPermissionRequestDialog();
        }
        return LocationResult(
          hasError: true,
          errorMessage: 'perlu izin lokasi',
          cityName: 'butuh izin',
          provinceName: 'tap buat izinkan',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        if (!silent && !_hasShownDialog) {
          _showPermissionDialog();
        }
        return LocationResult(
          hasError: true,
          errorMessage: 'izin lokasi ditolak',
          cityName: 'izin mati',
          provinceName: 'buka pengaturan',
        );
      }

      debugPrint('📍 Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint(
          '📍 Position obtained: ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = 'Kota tidak ditemukan';
      String province = '';
      String countryCode = '';

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        city = place.subAdministrativeArea ??
            place.locality ??
            'Kota tidak ditemukan';
        province = place.administrativeArea ?? '';
        countryCode = place.isoCountryCode ?? '';
        debugPrint('📍 Location found: $city, $province ($countryCode)');
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: city,
        provinceName: province,
        isoCountryCode: countryCode,
        hasError: false,
      );
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return LocationResult(
        hasError: true,
        errorMessage: 'gagal memuat lokasi: $e',
        cityName: 'gagal memuat',
        provinceName: 'tap buat coba lagi',
      );
    }
  }

  void _showGPSDialog() {
    _hasShownDialog = true;
    _showPremiumDialog(
      title: 'lokasi belum aktif',
      message:
          'nyalain lokasi dulu yuk biar jadwal sholat dan arah kiblat kamu pas.',
      onConfirm: () async {
        Get.back();
        _hasShownDialog = false;
        await Geolocator.openLocationSettings();
      },
      confirmText: 'buka pengaturan',
    );
  }

  void _showPermissionRequestDialog() {
    _hasShownDialog = true;
    _showPremiumDialog(
      title: 'perlu izin lokasi',
      message:
          'izinin akses lokasi ya biar jadwal sholat di tempat kamu akurat.',
      onConfirm: () async {
        Get.back();
        _hasShownDialog = false;
        await Geolocator.requestPermission();
      },
      confirmText: 'izinkan',
    );
  }

  void _showPermissionDialog() {
    _hasShownDialog = true;
    _showPremiumDialog(
      title: 'izin lokasi ditolak',
      message:
          'izin lokasi belum diaktifkan. buka pengaturan buat ngizinin ya.',
      onConfirm: () async {
        Get.back();
        _hasShownDialog = false;
        await Geolocator.openAppSettings();
      },
      confirmText: 'buka pengaturan',
    );
  }

  void _showPremiumDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmText,
  }) {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? Colors.black : Colors.white;
    final fgColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.white : Colors.black;

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(30.h),
            border: Border.all(color: borderColor, width: 4.w),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/lokasi_icon.svg',
                width: 48.sp,
                height: 48.sp,
                colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outlined(
                      text: 'nanti aja',
                      height: 48.h,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      borderWidth: 4.w,
                      onTap: () {
                        Get.back();
                        _hasShownDialog = false;
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: AppButton.filled(
                      text: confirmText,
                      height: 48.h,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
