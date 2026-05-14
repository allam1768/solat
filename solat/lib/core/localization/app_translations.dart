import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'settings': 'Settings',
          'preferences': 'Preferences',
          'dark_mode': 'Dark Mode',
          'switch_theme': 'Switch visual theme',
          'smart_reminder': 'Smart Reminder',
          'language': 'Language',
          'device_specific': 'Device Specific',
          'action_required': 'Action Required',
          'setup_permissions': 'Tap to setup missing permissions for reminders to work properly.',
          
          // Profiles
          'basic': 'BASIC',
          'basic_subtitle': 'ESSENTIAL ALERTS',
          'basic_desc': 'Adhan notifications at start, +30m, and -30m before prayer time ends.',
          'smart': 'SMART',
          'balanced_system': 'SMART SYSTEM',
          'smart_desc': 'Adhan notifications at start, +30m, and aggressive overlays during the final 30 minutes.',
          'recommended': 'RECOMMENDED',

          // Home
          'loading_location': 'Loading location...',
          'fajr': 'Fajr',
          'sunrise': 'Sunrise',
          'dhuhr': 'Dhuhr',
          'asr': 'Asr',
          'maghrib': 'Maghrib',
          'isha': 'Isha',
          'next_prayer': 'Next Prayer',
          'friday_prayer': 'Friday Prayer',
          'friday_reminder': 'Friday Reminder',
          'friday_reminder_desc': 'Remind me to prepare 50 and 30 minutes before Friday prayer.',
          'friday_prep_title': 'Friday Preparation',
          'friday_prep_body': 'It\'s almost time for Friday prayer. Let\'s get ready!',
          
          // Qibla
          'qibla_finder': 'Qibla Finder',
          'calibrate': 'Please calibrate your compass by moving your phone in a ∞ shape.',
          'location_ready': 'Location Ready',
          'location_access_failed': 'Location Access Failed',
          'try_again': 'Try again',
          
          // Location Specific
          'location_services_off': 'Location Services Off',
          'gps_off_desc': 'This app needs location services to show prayer times for your area. Enable location services now?',
          'open_settings': 'Open Settings',
          'not_now': 'Not now',
          'permission_required': 'Location Permission Required',
          'permission_desc': 'This app needs location permission to show prayer times for your area. Grant permission now?',
          'grant_permission': 'Grant Permission',
          'permission_denied': 'Location Permission Denied',
          'permission_denied_desc': 'Location permission is required to show prayer times. Please enable it in the app settings.',
          'location_services_off_short': 'Location services off',
          'tap_to_enable': 'Tap to enable',
          'permission_required_short': 'Permission required',
          'tap_to_grant': 'Tap to grant',
          'permanent_denied_short': 'Open Settings',
          'to_enable_permission': 'to enable permission',
          'failed_to_load': 'Failed to load',
          'tap_to_retry': 'Tap to retry',
          'city_not_found': 'City not found',
          
          // Support
          'support_feedback': 'Support & Feedback',
          'feedback': 'Send Feedback',
          'feedback_desc': 'Help us improve Salat by sharing your thoughts or reporting issues.',
        },
        'id_ID': {
          'settings': 'Pengaturan',
          'preferences': 'Preferensi',
          'dark_mode': 'Mode Gelap',
          'switch_theme': 'Ganti tema visual',
          'smart_reminder': 'Pengingat Pintar',
          'language': 'Bahasa',
          'device_specific': 'Spesifik Perangkat',
          'action_required': 'Tindakan Diperlukan',
          'setup_permissions': 'Ketuk untuk mengatur izin yang kurang agar pengingat berjalan lancar.',
          
          // Profiles
          'basic': 'BASIC',
          'basic_subtitle': 'PENGINGAT DASAR',
          'basic_desc': 'Notifikasi di awal waktu, +30 menit, dan -30 menit sebelum waktu habis.',
          'smart': 'SMART',
          'balanced_system': 'SISTEM PINTAR',
          'smart_desc': 'Notifikasi di awal waktu, +30 menit, dan overlay agresif di 30 menit terakhir.',
          'recommended': 'REKOMENDASI',

          // Home
          'loading_location': 'Memuat lokasi...',
          'fajr': 'Subuh',
          'sunrise': 'Terbit',
          'dhuhr': 'Dzuhur',
          'asr': 'Ashar',
          'maghrib': 'Maghrib',
          'isha': 'Isya',
          'next_prayer': 'Waktu Sholat Berikutnya',
          'friday_prayer': 'Jumatan',
          'friday_reminder': 'Pengingat Jumatan',
          'friday_reminder_desc': 'Ingatkan untuk bersiap 50 dan 30 menit sebelum Jumatan.',
          'friday_prep_title': 'Persiapan Jumatan',
          'friday_prep_body': 'Sudah hampir waktu Jumatan. Yuk, bersiap-siap!',
          
          // Qibla
          'qibla_finder': 'Pencari Kiblat',
          'calibrate': 'Kalibrasi kompas dengan menggerakkan HP membentuk angka ∞.',
          'location_ready': 'Lokasi Siap',
          'location_access_failed': 'Akses Lokasi Gagal',
          'try_again': 'Coba lagi',

          // Location Specific
          'location_services_off': 'Layanan Lokasi Mati',
          'gps_off_desc': 'Aplikasi ini butuh layanan lokasi untuk menampilkan jadwal sholat di area lu. Nyalakan sekarang?',
          'open_settings': 'Buka Pengaturan',
          'not_now': 'Gak sekarang',
          'permission_required': 'Izin Lokasi Diperlukan',
          'permission_desc': 'Aplikasi ini butuh izin lokasi untuk menampilkan jadwal sholat di area lu. Berikan izin sekarang?',
          'grant_permission': 'Berikan Izin',
          'permission_denied': 'Izin Lokasi Ditolak',
          'permission_denied_desc': 'Izin lokasi diperlukan untuk menampilkan jadwal sholat. Silakan aktifkan di pengaturan aplikasi.',
          'location_services_off_short': 'Layanan lokasi mati',
          'tap_to_enable': 'Ketuk untuk mengaktifkan',
          'permission_required_short': 'Izin diperlukan',
          'tap_to_grant': 'Ketuk untuk berikan izin',
          'permanent_denied_short': 'Buka Pengaturan',
          'to_enable_permission': 'untuk aktifkan izin',
          'failed_to_load': 'Gagal memuat',
          'tap_to_retry': 'Ketuk untuk coba lagi',
          'city_not_found': 'Kota tidak ditemukan',

          // Support
          'support_feedback': 'Bantuan & Masukan',
          'feedback': 'Kirim Masukan',
          'feedback_desc': 'Bantu kami mengembangkan Salat dengan berbagi pemikiran atau melaporkan masalah.',
        },
      };
}
