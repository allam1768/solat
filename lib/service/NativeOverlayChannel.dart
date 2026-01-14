import 'package:flutter/services.dart';

class NativeOverlayChannel {
  static const MethodChannel _channel =
      MethodChannel('solat/native_overlay');

  /// Kirim jadwal ke Android (format HH:mm untuk tiap waktu).
  static Future<void> schedulePrayerOverlays({
    required String fajrTime,
    required String sunriseTime,
    required String dhuhrTime,
    required String asrTime,
    required String maghribTime,
    required String ishaTime,
  }) async {
    try {
      await _channel.invokeMethod('schedulePrayerOverlays', {
        'fajr': fajrTime,
        'sunrise': sunriseTime,
        'dhuhr': dhuhrTime,
        'asr': asrTime,
        'maghrib': maghribTime,
        'isha': ishaTime,
      });
    } catch (e) {
      // Biarkan gagal diam-diam supaya tidak nge-crash UI
    }
  }

  static Future<void> cancelPrayerOverlays() async {
    try {
      await _channel.invokeMethod('cancelPrayerOverlays');
    } catch (_) {}
  }
}

