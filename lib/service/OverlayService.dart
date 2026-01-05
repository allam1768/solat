import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  final _storage = GetStorage();

  // Storage keys
  static const String overlayDurationKey = 'overlay_duration';

  // Default duration in minutes
  static const int defaultDuration = 5;

  // Get overlay duration from settings (in minutes)
  int getOverlayDuration() {
    return _storage.read(overlayDurationKey) ?? defaultDuration;
  }

  // Set overlay duration (in minutes)
  Future<void> setOverlayDuration(int minutes) async {
    await _storage.write(overlayDurationKey, minutes);
  }

  // Show overlay with prayer info
  Future<void> showPrayerOverlay({
    required String prayerName,
    required String message,
    required String nextPrayerTime,
    required String currentTime,
  }) async {
    try {
      // Check if overlay permission is granted
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (hasPermission != true) {
        debugPrint('❌ Overlay permission not granted');
        return;
      }

      // Check if overlay is already active
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive == true) {
        debugPrint('⚠️ Overlay already active, closing first...');
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      debugPrint('📱 Showing overlay for: $prayerName');

      // Share data to overlay BEFORE showing
      await FlutterOverlayWindow.shareData({
        'prayerName': prayerName,
        'message': message,
        'nextPrayerTime': nextPrayerTime,
        'currentTime': currentTime,
        'duration': getOverlayDuration(),
      });

      debugPrint('✅ Data shared to overlay');

      // Small delay to ensure data is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // 🔥 WORKAROUND: Pakai pixel sangat besar untuk memastikan fullscreen
      // Ambil ukuran layar maksimal (biasanya HP max 3000x3000 pixel)
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        height: 3000,  // 🔥 Paksa tinggi besar
        width: 2000,   // 🔥 Paksa lebar besar
        alignment: OverlayAlignment.center,
      );

      debugPrint('✅ Overlay command executed for: $prayerName');

    } catch (e) {
      debugPrint('❌ Error showing overlay: $e');
    }
  }

  // Close overlay
  Future<void> closeOverlay() async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive == true) {
        await FlutterOverlayWindow.closeOverlay();
        debugPrint('🗙 Overlay closed');
      }
    } catch (e) {
      debugPrint('❌ Error closing overlay: $e');
    }
  }

  // Request overlay permission
  Future<bool> requestOverlayPermission() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();

    if (hasPermission == true) return true;

    final granted = await FlutterOverlayWindow.requestPermission();
    return granted == true;
  }

  // Check if overlay is currently active
  Future<bool> isOverlayActive() async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      return isActive ?? false;
    } catch (e) {
      debugPrint('❌ Error checking overlay status: $e');
      return false;
    }
  }
}