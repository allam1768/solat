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

class HomeController extends GetxController with WidgetsBindingObserver {
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
  bool _hasShownDialog = false;
  bool _hasInitializedData = false; // ✅ Flag biar data cuma diambil sekali

  Rx<Map<String, String>?> get prayerTimes => Rx<Map<String, String>?>({
    'Fajr': fajrTime.value,
    'Sunrise': sunriseTime.value,
    'Dhuhr': dhuhrTime.value,
    'Asr': asrTime.value,
    'Maghrib': maghribTime.value,
    'Isha': ishaTime.value,
  });

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startClock(); // ✅ Clock tetap jalan
    // ✅ TIDAK auto-fetch data di sini
  }

  @override
  void onReady() {
    super.onReady();
    // ✅ Fetch data PAS screen udah ready (user udah liat screen)
    if (!_hasInitializedData) {
      _hasInitializedData = true;
      debugPrint('🏠 Home screen ready, fetching data...');
      _requestLocationPermissionAndFetch();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ Saat app kembali dari background (Settings), re-check location
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed, rechecking location...');
      Future.delayed(const Duration(milliseconds: 500), () {
        _requestLocationPermissionAndFetch();
      });
    }
  }

  Future<void> _requestLocationPermissionAndFetch() async {
    try {
      isLoadingLocation.value = true;
      locationError.value = '';

      // ✅ Check GPS dulu, tapi DIAM aja kalau mati
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError.value = 'GPS tidak aktif';
        cityName.value = 'GPS Mati';
        provinceName.value = 'Tap untuk aktifkan';
        isLoadingLocation.value = false;
        // ✅ TIDAK auto-show dialog, biarkan user yang tap
        return;
      }

      // ✅ Check permission, tapi DIAM aja kalau belum ada
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        locationError.value = 'Izin lokasi diperlukan';
        cityName.value = 'Izin Lokasi Diperlukan';
        provinceName.value = 'Tap untuk aktifkan';
        isLoadingLocation.value = false;
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Izin lokasi ditolak permanen';
        cityName.value = 'Buka Pengaturan';
        provinceName.value = 'untuk izin lokasi';
        isLoadingLocation.value = false;
        return;
      }

      // ✅ Kalau permission OK, baru ambil lokasi
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
      debugPrint('❌ Error getting location: $e');
      locationError.value = 'Gagal mendapatkan lokasi';
      cityName.value = 'Gagal memuat';
      provinceName.value = 'Tap untuk coba lagi';
      isLoadingLocation.value = false;
    }
  }

  // ✅ Function baru: untuk handle tap pada location card
  Future<void> handleLocationTap() async {
    if (locationError.value.isEmpty) {
      // Kalau tidak ada error, refresh aja
      await refreshLocation();
      return;
    }

    // ✅ Kalau GPS mati, buka dialog GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!_hasShownDialog) {
        _hasShownDialog = true;
        _showGPSDialog();
      }
      return;
    }

    // ✅ Kalau permission denied, buka dialog permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (!_hasShownDialog) {
        _hasShownDialog = true;
        _showPermissionRequestDialog();
      }
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!_hasShownDialog) {
        _hasShownDialog = true;
        _showPermissionDialog();
      }
      return;
    }

    // Kalau semua OK, refresh
    await refreshLocation();
  }

  void _showGPSDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('GPS Tidak Aktif'),
        content: const Text(
            'Aplikasi membutuhkan GPS untuk menampilkan jadwal sholat sesuai lokasi Anda. Aktifkan GPS sekarang?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _hasShownDialog = false;
            },
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _hasShownDialog = false;
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

  void _showPermissionRequestDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Izin Lokasi Diperlukan'),
        content: const Text(
            'Aplikasi membutuhkan izin lokasi untuk menampilkan jadwal sholat sesuai lokasi Anda. Berikan izin sekarang?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _hasShownDialog = false;
            },
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _hasShownDialog = false;
              LocationPermission permission = await Geolocator.requestPermission();
              if (permission == LocationPermission.whileInUse ||
                  permission == LocationPermission.always) {
                await refreshLocation();
              }
            },
            child: const Text('Berikan Izin'),
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
            onPressed: () {
              Get.back();
              _hasShownDialog = false;
            },
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _hasShownDialog = false;
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
    _hasShownDialog = false; // Reset dialog flag
    await _requestLocationPermissionAndFetch();
  }

  Future<void> _fetchPrayerTimes() async {
    if (latitude == null || longitude == null) {
      debugPrint('Koordinat belum tersedia');
      return;
    }

    try {
      isLoadingPrayer.value = true;

      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      String url = 'https://api.aladhan.com/v1/timings/$timestamp'
          '?latitude=$latitude'
          '&longitude=$longitude'
          '&method=3';

      debugPrint('Fetching prayer times from: $url');

      final response = await http.get(Uri.parse(url));

      debugPrint('Response status: ${response.statusCode}');

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

        await _scheduleNotifications();
        await _scheduleOverlays();
      } else {
        debugPrint('Failed to load prayer times: ${response.statusCode}');
        fajrTime.value = 'Error';
        sunriseTime.value = 'Error';
        dhuhrTime.value = 'Error';
        asrTime.value = 'Error';
        maghribTime.value = 'Error';
        ishaTime.value = 'Error';
        isLoadingPrayer.value = false;
      }
    } catch (e) {
      debugPrint('Error fetching prayer times: $e');
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
      debugPrint('❌ Waktu sholat belum lengkap, skip scheduling notifications');
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('🔔 Scheduling notifications...');

      await _notificationService.schedulePrayerNotifications(
        fajrTime: fajrTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );

      await _notificationService.checkPendingNotifications();
    } catch (e) {
      debugPrint('❌ Error scheduling notifications: $e');
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
      debugPrint('❌ Waktu sholat belum lengkap, skip scheduling overlays');
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('📱 Scheduling overlays...');

      await _overlayScheduler.scheduleOverlayTriggers(
        fajrTime: fajrTime.value,
        sunriseTime: sunriseTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );

      debugPrint('✅ Overlays scheduled successfully');
    } catch (e) {
      debugPrint('❌ Error scheduling overlays: $e');
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
      debugPrint('Error checking current prayer: $e');
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
      debugPrint('Error parsing time "$time": $e');
      return null;
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}