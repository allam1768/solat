import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && !_hasShownDialog) {
          _showGPSDialog();
        }
        return LocationResult(
          hasError: true,
          errorMessage: 'location_services_off'.tr,
          cityName: 'location_services_off_short',
          provinceName: 'tap_to_enable',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!silent && !_hasShownDialog) {
          _showPermissionRequestDialog();
        }
        return LocationResult(
          hasError: true,
          errorMessage: 'permission_required'.tr,
          cityName: 'permission_required_short',
          provinceName: 'tap_to_grant',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        if (!silent && !_hasShownDialog) {
          _showPermissionDialog();
        }
        return LocationResult(
          hasError: true,
          errorMessage: 'permission_denied'.tr,
          cityName: 'permanent_denied_short',
          provinceName: 'to_enable_permission',
        );
      }

      debugPrint('📍 Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint('📍 Position obtained: ${position.latitude}, ${position.longitude}');
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String city = 'city_not_found';
      String province = '';
      String countryCode = '';

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        city = place.subAdministrativeArea ?? place.locality ?? 'City not found';
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
        errorMessage: '${'failed_to_load'.tr}: $e',
        cityName: 'failed_to_load',
        provinceName: 'tap_to_retry',
      );
    }
  }

  void _showGPSDialog() {
    _hasShownDialog = true;
    _showPremiumDialog(
      title: 'location_services_off'.tr,
      message: 'gps_off_desc'.tr,
      onConfirm: () async {
        Get.back();
        _hasShownDialog = false;
        await Geolocator.openLocationSettings();
      },
      confirmText: 'open_settings'.tr,
    );
  }

  void _showPermissionRequestDialog() {
    _hasShownDialog = true;
    _showPremiumDialog(
      title: 'permission_required'.tr,
      message: 'permission_desc'.tr,
      onConfirm: () async {
        Get.back();
        _hasShownDialog = false;
        await Geolocator.requestPermission();
      },
      confirmText: 'grant_permission'.tr,
    );
  }

  void _showPermissionDialog() {
    _hasShownDialog = true;
    _showPremiumDialog(
      title: 'permission_denied'.tr,
      message: 'permission_denied_desc'.tr,
      onConfirm: () async {
        Get.back();
        _hasShownDialog = false;
        await Geolocator.openAppSettings();
      },
      confirmText: 'open_settings'.tr,
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
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 48, color: fgColor),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: fgColor.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: fgColor,
                        side: BorderSide(color: borderColor, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        _hasShownDialog = false;
                      },
                      child: Text('not_now'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fgColor,
                        foregroundColor: bgColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: onConfirm,
                      child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
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
