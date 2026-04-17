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

  var cityName = 'Loading location...'.obs;
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

  var currentPrayerName = ''.obs;

  double? latitude;
  double? longitude;

  Timer? _timer;
  bool _hasShownDialog = false;

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
    // ✅ Langsung fetch data saat init
    debugPrint('HomeController initialized, fetching location...');
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
    // ✅ When app returns from background (e.g., Settings), re-check location
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, rechecking location...');
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
        locationError.value = 'Location services are turned off';
        cityName.value = 'Location services off';
        provinceName.value = 'Tap to enable';
        isLoadingLocation.value = false;
        return;
      }

      // ✅ Check permission, but stay silent until user taps
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        locationError.value = 'Location permission is required';
        cityName.value = 'Location permission required';
        provinceName.value = 'Tap to grant';
        isLoadingLocation.value = false;
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        locationError.value = 'Location permission permanently denied';
        cityName.value = 'Open Settings';
        provinceName.value = 'to enable permission';
        isLoadingLocation.value = false;
        return;
      }

      // ✅ If permission is OK, fetch location
      debugPrint('📍 Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      latitude = position.latitude;
      longitude = position.longitude;

      debugPrint('📍 Position obtained: $latitude, $longitude');
      debugPrint('📍 Getting address from coordinates...');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        cityName.value =
            place.subAdministrativeArea ?? place.locality ?? 'City not found';
        provinceName.value = place.administrativeArea ?? '';
        debugPrint(
            '📍 Location found: ${cityName.value}, ${provinceName.value}');
      } else {
        cityName.value = 'Location not found';
        provinceName.value = '';
      }

      isLoadingLocation.value = false;

      // ✅ Fetch prayer times immediately after getting location
      debugPrint('🕌 Fetching prayer times...');
      await _fetchPrayerTimes();
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      locationError.value = 'Failed to get location';
      cityName.value = 'Failed to load';
      provinceName.value = 'Tap to retry';
      isLoadingLocation.value = false;
    }
  }

  // ✅ Function baru: untuk handle tap pada location card
  Future<void> handleLocationTap() async {
    if (locationError.value.isEmpty) {
      // If there's no error, just refresh
      await refreshLocation();
      return;
    }

    // ✅ If location services are off, show dialog
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!_hasShownDialog) {
        _hasShownDialog = true;
        _showGPSDialog();
      }
      return;
    }

    // ✅ If permission denied, show request dialog
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

    // If all OK, refresh
    await refreshLocation();
  }

  void _showGPSDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Location Services Off'),
        content: const Text(
            'This app needs location services to show prayer times for your area. Enable location services now?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _hasShownDialog = false;
            },
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _hasShownDialog = false;
              await Geolocator.openLocationSettings();
              await Future.delayed(const Duration(seconds: 1));
              await refreshLocation();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPermissionRequestDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
            'This app needs location permission to show prayer times for your area. Grant permission now?'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _hasShownDialog = false;
            },
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _hasShownDialog = false;
              LocationPermission permission =
                  await Geolocator.requestPermission();
              if (permission == LocationPermission.whileInUse ||
                  permission == LocationPermission.always) {
                await refreshLocation();
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
            'Location permission is required to show prayer times. Please enable it in the app settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _hasShownDialog = false;
            },
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              _hasShownDialog = false;
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> refreshLocation() async {
    _hasShownDialog = false;
    await _requestLocationPermissionAndFetch();
  }

  Future<void> _fetchPrayerTimes() async {
    if (latitude == null || longitude == null) {
      debugPrint('Coordinates not available yet');
      return;
    }

    try {
      isLoadingPrayer.value = true;

      String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());

      String url = 'https://api.aladhan.com/v1/timings/$formattedDate'
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

        debugPrint('✅ Prayer times loaded successfully');
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
      debugPrint('Prayer times incomplete; skipping notification scheduling');
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('Scheduling notifications...');

      await _notificationService.schedulePrayerNotifications(
        fajrTime: fajrTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );

      await _notificationService.checkPendingNotifications();
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
      Get.snackbar(
        'Error',
        'Failed to enable notifications: $e',
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
      debugPrint('Prayer times incomplete; skipping overlay scheduling');
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('Scheduling overlays...');

      await _overlayScheduler.scheduleOverlayTriggers(
        fajrTime: fajrTime.value,
        sunriseTime: sunriseTime.value,
        dhuhrTime: dhuhrTime.value,
        asrTime: asrTime.value,
        maghribTime: maghribTime.value,
        ishaTime: ishaTime.value,
      );

      debugPrint('Overlays scheduled successfully');
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
