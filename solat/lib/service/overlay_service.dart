import 'dart:io';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class OverlayService {
  static final OverlayService _instance = OverlayService._internal();
  factory OverlayService() => _instance;
  OverlayService._internal();

  final _storage = GetStorage();

  // Storage keys
  static const String overlayAttemptKey = 'overlay_attempt_';

  // Get current attempt count for specific prayer
  int getAttemptCount(String prayerName) {
    return _storage.read('$overlayAttemptKey$prayerName') ?? 0;
  }

  // Increment attempt count
  Future<void> incrementAttempt(String prayerName) async {
    final current = getAttemptCount(prayerName);
    await _storage.write('$overlayAttemptKey$prayerName', current + 1);
  }

  // Reset attempt count (when prayer done)
  Future<void> resetAttempt(String prayerName) async {
    await _storage.write('$overlayAttemptKey$prayerName', 0);
  }

  // Show prayer overlay with progressive intensity
  Future<void> showPrayerOverlay({
    required String prayerName,
    required String message,
    required String nextPrayerTime,
    required String currentTime,
    int? forceAttempt,
  }) async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();

      if (hasPermission != true) {
        debugPrint('❌ Overlay permission not granted');
        return;
      }

      final isActive = await FlutterOverlayWindow.isActive();

      if (isActive == true) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final attempt = forceAttempt ?? getAttemptCount(prayerName);
      final intensity = _getIntensityLevel(attempt);

      final dataToShare = {
        'prayerName': prayerName,
        'message': message,
        'nextPrayerTime': nextPrayerTime,
        'currentTime': currentTime,
        'attempt': attempt,
        'intensity': intensity.name,
        'timeoutSeconds': _getTimeoutSeconds(attempt),
      };

      try {
        await FlutterOverlayWindow.shareData(dataToShare);
      } catch (e) {
        debugPrint('❌ Error sharing data: $e');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        if (intensity == OverlayIntensity.critical) {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            width: WindowSize.fullCover,
            height: WindowSize.fullCover,
            alignment: OverlayAlignment.center,
            flag: OverlayFlag.defaultFlag,
          );
        } else {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            height: WindowSize.fullCover,
            width: WindowSize.fullCover,
            alignment: OverlayAlignment.center,
            flag: OverlayFlag.defaultFlag,
          );
        }
      } catch (e) {
        debugPrint('❌ Error showing overlay UI: $e');
        rethrow;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ Error showing overlay: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Get intensity level based on attempt (3 LEVELS ONLY)
  OverlayIntensity _getIntensityLevel(int attempt) {
    if (attempt == 0) return OverlayIntensity.gentle;   // Overlay 1: gentle
    if (attempt == 1) return OverlayIntensity.high;     // Overlay 2: high
    return OverlayIntensity.critical;                    // Overlay 3: CRITICAL
  }

  // Get timeout duration based on attempt
  int _getTimeoutSeconds(int attempt) {
    switch (attempt) {
      case 0: return 180; // Gentle: 3 minutes
      case 1: return 180; // High: 3 minutes
      default: return 0;  // Critical: No timeout (persistent)
    }
  }

  Future<void> closeOverlay() async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      if (isActive == true) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (e) {
      debugPrint('❌ Error closing overlay: $e');
    }
  }

  Future<bool> requestOverlayPermission() async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (hasPermission == true) {
        return true;
      }

      final granted = await FlutterOverlayWindow.requestPermission();
      return granted == true;
    } catch (e) {
      debugPrint('❌ Error requesting overlay permission: $e');
      return false;
    }
  }

  Future<bool> isOverlayActive() async {
    try {
      final isActive = await FlutterOverlayWindow.isActive();
      return isActive ;
    } catch (e) {
      debugPrint('❌ Error checking overlay status: $e');
      return false;
    }
  }

  Future<bool> hasOverlayPermission() async {
    try {
      if (Platform.isAndroid) {
        final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
        return hasPermission ;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error checking overlay permission: $e');
      return false;
    }
  }
}

// Intensity levels (3 LEVELS ONLY)
enum OverlayIntensity {
  gentle,   // Overlay 1: Popup, no vibration, 3 min timeout
  high,     // Overlay 2: Popup, vibration, 3 min timeout
  critical, // Overlay 3: Full screen, continuous vibration, NO timeout
}