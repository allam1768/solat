class PrayerTimeModel {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  PrayerTimeModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    // Al-Adhan API returns times with the timezone in parentheses, e.g., "04:30 (+07)"
    // We clean it up here so the Controller receives only pure times like "04:30".
    String cleanTime(String raw) {
      if (raw.contains('(')) {
        raw = raw.split('(')[0].trim();
      }
      return raw;
    }

    final timings = json['data']['timings'];
    return PrayerTimeModel(
      fajr: cleanTime(timings['Fajr'] ?? '--:--'),
      sunrise: cleanTime(timings['Sunrise'] ?? '--:--'),
      dhuhr: cleanTime(timings['Dhuhr'] ?? '--:--'),
      asr: cleanTime(timings['Asr'] ?? '--:--'),
      maghrib: cleanTime(timings['Maghrib'] ?? '--:--'),
      isha: cleanTime(timings['Isha'] ?? '--:--'),
    );
  }

  // Fallback for errors
  factory PrayerTimeModel.error() {
    return PrayerTimeModel(
      fajr: 'Error',
      sunrise: 'Error',
      dhuhr: 'Error',
      asr: 'Error',
      maghrib: 'Error',
      isha: 'Error',
    );
  }
}
