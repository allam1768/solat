import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get_storage/get_storage.dart';
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
  DateTime? _lastFetchTime;

  double? latitude;
  double? longitude;
  String? isoCountryCode;

  Timer? _timer;

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
          DateTime.now().difference(_lastFetchTime!) > const Duration(minutes: 5)) {
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
      
      // Calculate locally using Adhan (no internet needed)
      await _fetchPrayerTimes();
      isLoadingLocation.value = false;
    }

    // 2. Try to get fresh location in the background
    final result = await _locationService.getCurrentLocation(silent: true);

    if (result.hasError) {
      // If fresh location fails (e.g. offline) and we don't have cache, show error
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
    final model =
        await _prayerTimeService.fetchPrayerTimes(latitude!, longitude!, isoCountryCode: isoCountryCode);

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
        backgroundColor: Colors.black,
        colorText: Colors.white,
        borderRadius: 10,
        margin: const EdgeInsets.all(15),
        borderWidth: 1.5,
        borderColor: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.error_outline, color: Colors.white),
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
    String locale = Get.locale?.languageCode ?? 'en';
    
    // Perlu initialize untuk locale tertentu jika belum
    initializeDateFormatting(locale);
    
    currentDay.value = DateFormat('EEEE', locale).format(now);
    currentDate.value = DateFormat('d MMMM yyyy', locale).format(now);
    
    // Update isFriday
    isFriday.value = now.weekday == DateTime.friday;
    
    _checkCurrentPrayer();
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
        currentPrayerKey.value = 'fajr';
      } else if (currentMinutes >= sunriseMinutes &&
          currentMinutes < dhuhrMinutes) {
        currentPrayerKey.value = '';
      } else if (currentMinutes >= dhuhrMinutes &&
          currentMinutes < asrMinutes) {
        currentPrayerKey.value = 'dhuhr';
      } else if (currentMinutes >= asrMinutes &&
          currentMinutes < maghribMinutes) {
        currentPrayerKey.value = 'asr';
      } else if (currentMinutes >= maghribMinutes &&
          currentMinutes < ishaMinutes) {
        currentPrayerKey.value = 'maghrib';
      } else if (currentMinutes >= ishaMinutes) {
        // ✅ Isya aktif dari waktu Isya sampai jam 23:59
        currentPrayerKey.value = 'isha';
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
