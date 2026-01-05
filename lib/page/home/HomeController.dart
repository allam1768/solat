import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:solat/core/app_colors.dart';
import 'dart:convert';
import '../../service/NotificationService.dart';
import '../../service/OverlaySchedulerService.dart';

class HomeController extends GetxController {
  final NotificationService _notificationService = NotificationService();
  final OverlaySchedulerService _overlayScheduler = OverlaySchedulerService();

  var cityName = 'Memuat lokasi...'.obs;
  var provinceName = ''.obs;
  var isLoadingLocation = true.obs;
  var locationError = ''.obs;

  var currentTime = '00:00:00'.obs;
  var currentDate = 'Memuat...'.obs;
  var currentDay = 'Memuat'.obs;

  var fajrTime = '--:--'.obs;
  var sunriseTime = '--:--'.obs;
  var dhuhrTime = '--:--'.obs;
  var asrTime = '--:--'.obs;
  var maghribTime = '--:--'.obs;
  var ishaTime = '--:--'.obs;
  var isLoadingPrayer = true.obs;

  var currentPrayerName = ''.obs;

  double? latitude;
  double? longitude;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _requestLocationPermissionAndFetch();
    _startClock();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> _requestLocationPermissionAndFetch() async {
    try {
      isLoadingLocation.value = true;
      locationError.value = '';

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'Lokasi tidak aktif';
        cityName.value = 'GPS Mati';
        provinceName.value = '';
        isLoadingLocation.value = false;
        _showGPSDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          locationError.value = 'Izin lokasi ditolak';
          cityName.value = 'Izin ditolak';
          provinceName.value = '';
          isLoadingLocation.value = false;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Izin lokasi ditolak permanen';
        cityName.value = 'Buka pengaturan';
        provinceName.value = 'untuk izin lokasi';
        isLoadingLocation.value = false;
        _showPermissionDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        cityName.value = place.subAdministrativeArea ??
            place.locality ??
            'Kota tidak ditemukan';
        provinceName.value = place.administrativeArea ?? '';
      } else {
        cityName.value = 'Lokasi tidak ditemukan';
        provinceName.value = '';
      }

      isLoadingLocation.value = false;

      await _fetchPrayerTimes();
    } catch (e) {
      print('Error getting location: $e');
      locationError.value = 'Gagal mendapatkan lokasi';
      cityName.value = 'Gagal memuat';
      provinceName.value = '';
      isLoadingLocation.value = false;
    }
  }

  void _showGPSDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('GPS Tidak Aktif'),
        content: const Text(
            'Aplikasi membutuhkan GPS untuk menampilkan jadwal sholat sesuai lokasi Anda. Aktifkan GPS sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openLocationSettings();
              await Future.delayed(const Duration(seconds: 1));
              await refreshLocation();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Izin Lokasi Ditolak'),
        content: const Text(
            'Aplikasi membutuhkan izin lokasi untuk menampilkan jadwal sholat. Silakan aktifkan izin lokasi di pengaturan aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await Geolocator.openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> refreshLocation() async {
    await _requestLocationPermissionAndFetch();
  }

  Future<void> _fetchPrayerTimes() async {
    if (latitude == null || longitude == null) {
      print('Koordinat belum tersedia');
      return;
    }

    try {
      isLoadingPrayer.value = true;

      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      String url = 'https://api.aladhan.com/v1/timings/$timestamp'
          '?latitude=$latitude'
          '&longitude=$longitude'
          '&method=3';

      print('Fetching prayer times from: $url');

      final response = await http.get(Uri.parse(url));

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];

        fajrTime.value = _formatPrayerTime(timings['Fajr']);
        sunriseTime.value = _formatPrayerTime(timings['Sunrise']);
        dhuhrTime.value = _formatPrayerTime(timings['Dhuhr']);
        asrTime.value = _formatPrayerTime(timings['Asr']);
        maghribTime.value = _formatPrayerTime(timings['Maghrib']);
        ishaTime.value = _formatPrayerTime(timings['Isha']);

        isLoadingPrayer.value = false;

        Future.delayed(const Duration(milliseconds: 100), () {
          _checkCurrentPrayer();
        });

        // 🔥 SCHEDULE NOTIFICATIONS
        await _scheduleNotifications();

        // 🔥 SCHEDULE OVERLAY TRIGGERS
        await _scheduleOverlays();
      } else {
        print('Failed to load prayer times: ${response.statusCode}');
        fajrTime.value = 'Error';
        sunriseTime.value = 'Error';
        dhuhrTime.value = 'Error';
        asrTime.value = 'Error';
        maghribTime.value = 'Error';
        ishaTime.value = 'Error';
        isLoadingPrayer.value = false;
      }
    } catch (e) {
      print('Error fetching prayer times: $e');
      fajrTime.value = 'Error';
      sunriseTime.value = 'Error';
      dhuhrTime.value = 'Error';
      asrTime.value = 'Error';
      maghribTime.value = 'Error';
      ishaTime.value = 'Error';
      isLoadingPrayer.value = false;
    }
  }

  Future<void> _scheduleNotifications() async {
    if (fajrTime.value == '--:--' ||
        dhuhrTime.value == '--:--' ||
        asrTime.value == '--:--' ||
        maghribTime.value == '--:--' ||
        ishaTime.value == '--:--') {
      print('❌ Waktu sholat belum lengkap, skip scheduling notifications');
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      print('📢 Scheduling notifications...');
      print('Fajr: ${fajrTime.value}');
      print('Dhuhr: ${dhuhrTime.value}');
      print('Asr: ${asrTime.value}');
      print('Maghrib: ${maghribTime.value}');
      print('Isha: ${ishaTime.value}');

      await _notificationService.schedulePrayerNotifications(
        fajrTime: fajrTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );

      await _notificationService.checkPendingNotifications();
    } catch (e) {
      print('❌ Error scheduling notifications: $e');
      Get.snackbar(
        '❌ Gagal',
        'Gagal mengaktifkan notifikasi: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.primary.withOpacity(0.8),
        colorText: Colors.white,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _scheduleOverlays() async {
    if (fajrTime.value == '--:--' ||
        sunriseTime.value == '--:--' ||
        dhuhrTime.value == '--:--' ||
        asrTime.value == '--:--' ||
        maghribTime.value == '--:--' ||
        ishaTime.value == '--:--') {
      print('❌ Waktu sholat belum lengkap, skip scheduling overlays');
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      print('📱 Scheduling overlays...');

      await _overlayScheduler.scheduleOverlayTriggers(
        fajrTime: fajrTime.value,
        sunriseTime: sunriseTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );

      print('✅ Overlays scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling overlays: $e');
    }
  }

  Future<void> testNotification() async {
    await _notificationService.showInstantNotification(
      title: '🕌 Test Notifikasi',
      body: 'Ini adalah notifikasi test. Notifikasi bekerja dengan baik!',
    );
  }

  String _formatPrayerTime(String time) {
    if (time.contains('(')) {
      time = time.split('(')[0].trim();
    }
    List<String> parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  void _startClock() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    DateTime now = DateTime.now();
    currentTime.value = DateFormat('HH:mm:ss').format(now);
    String dayName = _getDayName(now.weekday);
    currentDay.value = dayName;
    String monthName = _getMonthName(now.month);
    currentDate.value = '${now.day} $monthName ${now.year}';
    _checkCurrentPrayer();
  }

  void _checkCurrentPrayer() {
    if (fajrTime.value == '--:--' ||
        sunriseTime.value == '--:--' ||
        dhuhrTime.value == '--:--' ||
        asrTime.value == '--:--' ||
        maghribTime.value == '--:--' ||
        ishaTime.value == '--:--' ||
        isLoadingPrayer.value) {
      currentPrayerName.value = '';
      return;
    }

    try {
      DateTime now = DateTime.now();
      int currentMinutes = now.hour * 60 + now.minute;

      int? fajrMinutes = _parseTimeToMinutes(fajrTime.value);
      int? sunriseMinutes = _parseTimeToMinutes(sunriseTime.value);
      int? dhuhrMinutes = _parseTimeToMinutes(dhuhrTime.value);
      int? asrMinutes = _parseTimeToMinutes(asrTime.value);
      int? maghribMinutes = _parseTimeToMinutes(maghribTime.value);
      int? ishaMinutes = _parseTimeToMinutes(ishaTime.value);

      if (fajrMinutes == null ||
          sunriseMinutes == null ||
          dhuhrMinutes == null ||
          asrMinutes == null ||
          maghribMinutes == null ||
          ishaMinutes == null) {
        currentPrayerName.value = '';
        return;
      }

      if (currentMinutes >= fajrMinutes && currentMinutes < sunriseMinutes) {
        currentPrayerName.value = 'Fajr';
      } else if (currentMinutes >= sunriseMinutes &&
          currentMinutes < dhuhrMinutes) {
        currentPrayerName.value = '';
      } else if (currentMinutes >= dhuhrMinutes &&
          currentMinutes < asrMinutes) {
        currentPrayerName.value = 'Dhuhr';
      } else if (currentMinutes >= asrMinutes &&
          currentMinutes < maghribMinutes) {
        currentPrayerName.value = 'Asr';
      } else if (currentMinutes >= maghribMinutes &&
          currentMinutes < ishaMinutes) {
        currentPrayerName.value = 'Maghrib';
      } else if (currentMinutes >= ishaMinutes && currentMinutes < 1440) {
        currentPrayerName.value = 'Isha';
      } else {
        currentPrayerName.value = '';
      }
    } catch (e) {
      print('Error checking current prayer: $e');
      currentPrayerName.value = '';
    }
  }

  int? _parseTimeToMinutes(String time) {
    try {
      if (time.isEmpty || time == '--:--' || time == 'Error') {
        return null;
      }
      List<String> parts = time.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return hour * 60 + minute;
      }
      return null;
    } catch (e) {
      print('Error parsing time "$time": $e');
      return null;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return '';
    }
  }
}