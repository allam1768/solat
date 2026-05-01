import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'native_overlay_channel.dart';

/// Versi baru OverlaySchedulerService:
/// - Tidak lagi menjadwalkan overlay via AwesomeNotifications
/// - Hanya jadi jembatan ke Android (AlarmManager + ForegroundService)
class OverlaySchedulerService {
  static final OverlaySchedulerService _instance =
      OverlaySchedulerService._internal();
  factory OverlaySchedulerService() => _instance;
  OverlaySchedulerService._internal();

  final _storage = GetStorage();

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
    final profile = _storage.read('reminderProfile') ?? 1;

    // GENTLE mode (0) TIDAK pakai overlay
    if (profile == 0) {
      debugPrint('Reminder Profile is GENTLE: Cancelling all native overlays');
      await cancelAllOverlayTriggers();
      return;
    }

    debugPrint('Scheduling native overlays via MethodChannel (Profile: $profile)...');
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
