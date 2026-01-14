import 'package:flutter/material.dart';
import 'NativeOverlayChannel.dart';

/// Versi baru OverlaySchedulerService:
/// - Tidak lagi menjadwalkan overlay via AwesomeNotifications
/// - Hanya jadi jembatan ke Android (AlarmManager + ForegroundService)
class OverlaySchedulerService {
  static final OverlaySchedulerService _instance =
      OverlaySchedulerService._internal();
  factory OverlaySchedulerService() => _instance;
  OverlaySchedulerService._internal();

  // Dibiarkan untuk kompatibilitas; sekarang hanya log saja
  Future<void> initializeOverlayChannel() async {
    debugPrint(
        'OverlaySchedulerService.initializeOverlayChannel(): native overlay mode, no-op on Flutter');
  }

  Future<void> scheduleOverlayTriggers({
    required String fajrTime,
    required String sunriseTime,
    required String dhuhrTime,
    required String asrTime,
    required String maghribTime,
    required String ishaTime,
  }) async {
    debugPrint('Scheduling native overlays via MethodChannel...');
    await NativeOverlayChannel.schedulePrayerOverlays(
      fajrTime: fajrTime,
      sunriseTime: sunriseTime,
      dhuhrTime: dhuhrTime,
      asrTime: asrTime,
      maghribTime: maghribTime,
      ishaTime: ishaTime,
    );
  }

  Future<void> cancelAllOverlayTriggers() async {
    await NativeOverlayChannel.cancelPrayerOverlays();
  }

  /// Dipanggil dari main.dart / NotificationController ketika user menandai sholat sudah selesai.
  /// Di mode overlay native, semua logika "done" (cancel alarm, stop service, dsb) sudah ditangani di Android.
  /// Di sini cukup no-op + log supaya kompatibel dan tidak error.
  Future<void> handlePrayerDone(String prayerName) async {
    debugPrint(
        'OverlaySchedulerService.handlePrayerDone("$prayerName") called (native overlay mode, no-op)');
    }
  }
