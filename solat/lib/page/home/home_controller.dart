import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get_storage/get_storage.dart';
import 'package:solat/core/app_colors.dart';
import '../../service/notification_service.dart';
import '../../service/overlay_scheduler_service.dart';
import '../../service/location_service.dart';
import '../../service/prayer_time_service.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final NotificationService _notificationService =
      Get.find<NotificationService>();
  final OverlaySchedulerService _overlayScheduler =
      Get.find<OverlaySchedulerService>();
  final LocationService _locationService = Get.find<LocationService>();
  final PrayerTimeService _prayerTimeService = Get.find<PrayerTimeService>();

  var cityName = 'loading_location'.obs;
  var provinceName = ''.obs;
  var isLoadingLocation = true.obs;
  var locationError = ''.obs;

  var currentTime = '00:00:00'.obs;
  var currentDate = 'Loading...'.obs;
  var currentDay = 'Loading'.obs;

  var fajrTime = '--:--'.obs;
  var sunriseTime = '--:--'.obs;
  var dhuhrTime = '--:--'.obs;
  var asrTime = '--:--'.obs;
  var maghribTime = '--:--'.obs;
  var ishaTime = '--:--'.obs;
  var isLoadingPrayer = true.obs;
  var isFriday = false.obs;

  var currentPrayerKey = ''.obs;
  var nextPrayerName = '--'.obs;
  var nextPrayerTime = '--:--'.obs;
  var qiblaDirectionText = '--°'.obs;

  DateTime? _lastFetchTime;

  double? latitude;
  double? longitude;
  String? isoCountryCode;

  Timer? _timer;

  Rx<Map<String, String>?> get prayerTimes => Rx<Map<String, String>?>({
        'Subuh': fajrTime.value,
        'Terbit': sunriseTime.value,
        'Dzuhur': dhuhrTime.value,
        'Ashar': asrTime.value,
        'Maghrib': maghribTime.value,
        'Isya': ishaTime.value,
      });

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startClock();
    _requestLocationPermissionAndFetch();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ Cek apakah sudah lewat 5 menit sejak fetch terakhir
      // Ini mencegah reload terus-terusan pas buka control panel atau pindah app bentar
      if (_lastFetchTime == null ||
          DateTime.now().difference(_lastFetchTime!) >
              const Duration(minutes: 5)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _requestLocationPermissionAndFetch();
        });
      }
    }
  }

  Future<void> _requestLocationPermissionAndFetch() async {
    isLoadingLocation.value = true;
    locationError.value = '';

    final storage = GetStorage();

    // 1. Try to load from cache first for immediate UI rendering & offline mode
    final cachedLat = storage.read<double>('last_lat');
    final cachedLng = storage.read<double>('last_lng');
    final cachedCity = storage.read<String>('last_city');
    final cachedProvince = storage.read<String>('last_province');
    final cachedIso = storage.read<String>('last_iso');

    if (cachedLat != null && cachedLng != null) {
      latitude = cachedLat;
      longitude = cachedLng;
      cityName.value = cachedCity ?? 'Offline Location';
      provinceName.value = cachedProvince ?? '';
      isoCountryCode = cachedIso;

      _updateQiblaDirection();
      // Calculate locally using Adhan (no internet needed)
      await _fetchPrayerTimes();
      isLoadingLocation.value = false;
    }

    // 2. Try to get fresh location in the background
    final result = await _locationService.getCurrentLocation(silent: true);

    if (result.hasError) {
      if (cachedLat == null) {
        locationError.value = result.errorMessage;
        cityName.value = result.cityName;
        provinceName.value = result.provinceName;
      }
      isLoadingLocation.value = false;
      return;
    }

    // 3. If fresh location succeeds, update variables, save to cache, and recalculate
    cityName.value = result.cityName;
    provinceName.value = result.provinceName;
    latitude = result.latitude;
    longitude = result.longitude;
    isoCountryCode = result.isoCountryCode;

    _updateQiblaDirection();

    storage.write('last_lat', result.latitude);
    storage.write('last_lng', result.longitude);
    storage.write('last_city', result.cityName);
    storage.write('last_province', result.provinceName);
    storage.write('last_iso', result.isoCountryCode);

    isLoadingLocation.value = false;
    await _fetchPrayerTimes();
  }

  Future<void> handleLocationTap() async {
    if (locationError.value.isEmpty) {
      await refreshLocation();
      return;
    }

    // Attempt to get location non-silently to trigger dialogs
    final result = await _locationService.getCurrentLocation(silent: false);
    if (!result.hasError && result.latitude != null) {
      await refreshLocation();
    }
  }

  Future<void> refreshLocation() async {
    await _requestLocationPermissionAndFetch();
  }

  Future<void> _fetchPrayerTimes() async {
    if (latitude == null || longitude == null) return;

    isLoadingPrayer.value = true;
    final model = await _prayerTimeService.fetchPrayerTimes(
        latitude!, longitude!,
        isoCountryCode: isoCountryCode);

    fajrTime.value = model.fajr;
    sunriseTime.value = model.sunrise;
    dhuhrTime.value = model.dhuhr;
    asrTime.value = model.asr;
    maghribTime.value = model.maghrib;
    ishaTime.value = model.isha;

    isLoadingPrayer.value = false;

    if (fajrTime.value != 'Error' && fajrTime.value != '--:--') {
      _lastFetchTime = DateTime.now(); // Simpan waktu fetch terakhir

      Future.delayed(const Duration(milliseconds: 100), () {
        _checkCurrentPrayer();
        _updateNextPrayer();
      });

      await _scheduleNotifications();
      await _scheduleOverlays();
    }
  }

  Future<void> _scheduleNotifications() async {
    try {
      await _notificationService.schedulePrayerNotifications(
        fajrTime: fajrTime.value,
        sunriseTime: sunriseTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );
      await _notificationService.checkPendingNotifications();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to enable notifications: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.black,
        colorText: AppColors.white,
        borderRadius: 10,
        margin: const EdgeInsets.all(15),
        borderWidth: 1.5,
        borderColor: AppColors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error_outline, color: AppColors.white),
      );
    }
  }

  Future<void> _scheduleOverlays() async {
    try {
      await _overlayScheduler.scheduleOverlayTriggers(
        fajrTime: fajrTime.value,
        sunriseTime: sunriseTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );
    } catch (e) {
      debugPrint('Error scheduling overlays: $e');
    }
  }

  Future<void> testNotification() async {
    await _notificationService.showInstantNotification(
      title: '🕌 Test Notification',
      body: 'This is a test notification. Notifications are working!',
    );
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

    // ✅ Lokalisasi Hari & Tanggal otomatis
    String locale = 'id_ID';

    // Perlu initialize untuk locale tertentu jika belum
    initializeDateFormatting(locale);

    currentDay.value = DateFormat('EEEE', locale).format(now);
    currentDate.value = DateFormat('d MMMM yyyy', locale).format(now);

    // Update isFriday
    isFriday.value = now.weekday == DateTime.friday;

    _checkCurrentPrayer();
    _updateNextPrayer();
  }

  void _updateQiblaDirection() {
    if (latitude == null || longitude == null) {
      qiblaDirectionText.value = '--°';
      return;
    }
    const double makkahLat = 21.4224779;
    const double makkahLng = 39.8251832;

    double lat1 = latitude! * pi / 180;
    double lng1 = longitude! * pi / 180;
    double lat2 = makkahLat * pi / 180;
    double lng2 = makkahLng * pi / 180;

    double dLng = lng2 - lng1;
    double y = sin(dLng) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    double bearing = atan2(y, x);
    double degrees = (bearing * 180 / pi + 360) % 360;

    String cardinal = _getCardinalDirection(degrees);
    qiblaDirectionText.value = '${degrees.toStringAsFixed(1)}° $cardinal';
  }

  String _getCardinalDirection(double degrees) {
    double normalized = (degrees % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'U';
    if (normalized >= 22.5 && normalized < 67.5) return 'TL';
    if (normalized >= 67.5 && normalized < 112.5) return 'T';
    if (normalized >= 112.5 && normalized < 157.5) return 'TG';
    if (normalized >= 157.5 && normalized < 202.5) return 'S';
    if (normalized >= 202.5 && normalized < 247.5) return 'BD';
    if (normalized >= 247.5 && normalized < 292.5) return 'B';
    return 'BL';
  }

  void _updateNextPrayer() {
    if (isLoadingPrayer.value ||
        fajrTime.value == '--:--' ||
        fajrTime.value == 'Error' ||
        dhuhrTime.value == '--:--' ||
        dhuhrTime.value == 'Error' ||
        asrTime.value == '--:--' ||
        asrTime.value == 'Error' ||
        maghribTime.value == '--:--' ||
        maghribTime.value == 'Error' ||
        ishaTime.value == '--:--' ||
        ishaTime.value == 'Error') {
      nextPrayerName.value = '--';
      nextPrayerTime.value = '--:--';
      return;
    }

    try {
      DateTime now = DateTime.now();
      int currentMinutes = now.hour * 60 + now.minute;

      int? fajrMinutes = _parseTimeToMinutes(fajrTime.value);
      int? dhuhrMinutes = _parseTimeToMinutes(dhuhrTime.value);
      int? asrMinutes = _parseTimeToMinutes(asrTime.value);
      int? maghribMinutes = _parseTimeToMinutes(maghribTime.value);
      int? ishaMinutes = _parseTimeToMinutes(ishaTime.value);

      if (fajrMinutes == null ||
          dhuhrMinutes == null ||
          asrMinutes == null ||
          maghribMinutes == null ||
          ishaMinutes == null) {
        nextPrayerName.value = '--';
        nextPrayerTime.value = '--:--';
        return;
      }

      if (currentMinutes < fajrMinutes) {
        nextPrayerName.value = 'Subuh';
        nextPrayerTime.value = fajrTime.value;
      } else if (currentMinutes < dhuhrMinutes) {
        nextPrayerName.value = isFriday.value ? 'Jumatan' : 'Dzuhur';
        nextPrayerTime.value = dhuhrTime.value;
      } else if (currentMinutes < asrMinutes) {
        nextPrayerName.value = 'Ashar';
        nextPrayerTime.value = asrTime.value;
      } else if (currentMinutes < maghribMinutes) {
        nextPrayerName.value = 'Maghrib';
        nextPrayerTime.value = maghribTime.value;
      } else if (currentMinutes < ishaMinutes) {
        nextPrayerName.value = 'Isya';
        nextPrayerTime.value = ishaTime.value;
      } else {
        nextPrayerName.value = 'Subuh';
        nextPrayerTime.value = fajrTime.value;
      }
    } catch (e) {
      nextPrayerName.value = '--';
      nextPrayerTime.value = '--:--';
    }
  }

  void _checkCurrentPrayer() {
    if (fajrTime.value == '--:--' ||
        sunriseTime.value == '--:--' ||
        dhuhrTime.value == '--:--' ||
        asrTime.value == '--:--' ||
        maghribTime.value == '--:--' ||
        ishaTime.value == '--:--' ||
        isLoadingPrayer.value ||
        fajrTime.value == 'Error') {
      currentPrayerKey.value = '';
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
        currentPrayerKey.value = '';
        return;
      }

      if (currentMinutes >= fajrMinutes && currentMinutes < sunriseMinutes) {
        currentPrayerKey.value = 'Subuh';
      } else if (currentMinutes >= sunriseMinutes &&
          currentMinutes < dhuhrMinutes) {
        currentPrayerKey.value = '';
      } else if (currentMinutes >= dhuhrMinutes &&
          currentMinutes < asrMinutes) {
        currentPrayerKey.value = 'Dzuhur';
      } else if (currentMinutes >= asrMinutes &&
          currentMinutes < maghribMinutes) {
        currentPrayerKey.value = 'Ashar';
      } else if (currentMinutes >= maghribMinutes &&
          currentMinutes < ishaMinutes) {
        currentPrayerKey.value = 'Maghrib';
      } else if (currentMinutes >= ishaMinutes) {
        // ✅ Isya aktif dari waktu Isya sampai jam 23:59
        currentPrayerKey.value = 'Isya';
      } else if (currentMinutes < fajrMinutes) {
        // ✅ Setelah jam 00:00 sampai Subuh, tidak ada yang aktif (permintaan user)
        currentPrayerKey.value = '';
      } else {
        currentPrayerKey.value = '';
      }
    } catch (e) {
      currentPrayerKey.value = '';
    }
  }

  int? _parseTimeToMinutes(String time) {
    if (time.isEmpty || time == '--:--' || time == 'Error') return null;
    List<String> parts = time.split(':');
    if (parts.length >= 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return null;
  }
}
