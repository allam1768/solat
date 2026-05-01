import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';
import '../../service/location_service.dart';

class QiblaController extends GetxController with GetSingleTickerProviderStateMixin, WidgetsBindingObserver {
  final LocationService _locationService = Get.find<LocationService>();

  var rotation = 0.0.obs;
  var qiblaDirection = 0.0.obs;
  var phoneHeading = 0.0.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var locationName = ''.obs;
  var needsCalibration = false.obs;

  StreamSubscription<CompassEvent>? compassSubscription;

  // ✅ ANIMATION - Untuk smooth rotation
  late AnimationController animationController;
  late Animation<double> rotationAnimation;
  double targetRotation = 0.0;
  
  // Vibration debounce
  DateTime? _lastVibrationTime;

  // Koordinat Ka'bah, Makkah
  final double makkahLat = 21.4224779;
  final double makkahLng = 39.8251832;

  @override
  void onInit() {
    super.onInit();

    // ✅ Setup animation controller (300ms duration, adjust sesuai selera)
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // Smooth tapi responsive
    );

    // ✅ Setup tween animation
    rotationAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut, // Smooth easing
    ))..addListener(() {
      rotation.value = rotationAnimation.value;
    });

    // ✅ Tambahkan observer lifecycle
    WidgetsBinding.instance.addObserver(this);
    
    initQibla();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ✅ BUG FIX: Hentikan sensor/vibrasi saat app di background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      debugPrint('Qibla: App paused, stopping compass subscription');
      compassSubscription?.cancel();
      compassSubscription = null;
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('Qibla: App resumed, restarting compass');
      listenToCompass();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Lepas observer
    compassSubscription?.cancel();
    animationController.dispose(); // ✅ Don't forget to dispose
    super.onClose();
  }

  Future<void> initQibla() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get user location directly from LocationService
      final result = await _locationService.getCurrentLocation(silent: false);
      
      if (result.hasError || result.latitude == null) {
        isLoading.value = false;
        errorMessage.value = result.errorMessage.isNotEmpty ? result.errorMessage : "Gagal mendapatkan lokasi. Pastikan GPS menyala.";
        return;
      }

      // Calculate qibla direction
      double qibla = calculateQiblaDirection(
        result.latitude!,
        result.longitude!,
      );
      qiblaDirection.value = qibla;

      // Get location name
      locationName.value = result.provinceName.isNotEmpty 
          ? '${result.cityName}, ${result.provinceName}' 
          : result.cityName;

      // Start listening to compass
      listenToCompass();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = "Terjadi kesalahan sistem: $e";
      debugPrint('Error initializing Qibla: $e');
    }
  }

  double calculateQiblaDirection(double userLat, double userLng) {
    // Convert degrees to radians
    double lat1 = userLat * pi / 180;
    double lng1 = userLng * pi / 180;
    double lat2 = makkahLat * pi / 180;
    double lng2 = makkahLng * pi / 180;

    // Calculate bearing using formula
    double dLng = lng2 - lng1;

    double y = sin(dLng) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);

    double bearing = atan2(y, x);

    // Convert to degrees and normalize to 0-360
    double bearingDegrees = (bearing * 180 / pi + 360) % 360;

    return bearingDegrees;
  }

  void listenToCompass() {
    compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        phoneHeading.value = event.heading!;
        
        // Cek akurasi kompas. Jika null atau error derajat lebih dari 15°, minta user kalibrasi
        final acc = event.accuracy;
        needsCalibration.value = (acc == null || acc > 15.0);

        // Calculate rotation: jarum harus selalu menunjuk ke kiblat
        // Formula: qiblaDirection - phoneHeading
        double needleRotation = qiblaDirection.value - phoneHeading.value;

        // Normalize to 0-360 untuk support semua case
        needleRotation = needleRotation % 360;
        if (needleRotation < 0) {
          needleRotation += 360;
        }

        _checkHapticFeedback(needleRotation);

        // ✅ SMOOTH ANIMATION - Animate dari current ke target
        _animateToRotation(needleRotation);
      }
    });
  }
  
  void _checkHapticFeedback(double currentRot) async {
      // Tolleransi 2 derajat
      bool isNearQibla = (currentRot <= 2 || currentRot >= 358);
      
      if (isNearQibla) {
          bool canVibrate = true;
          if (_lastVibrationTime != null) {
              final diff = DateTime.now().difference(_lastVibrationTime!);
              if (diff.inSeconds < 2) {
                  canVibrate = false;
              }
          }
          
          if (canVibrate) {
              _lastVibrationTime = DateTime.now();
              // Try to vibrate
              bool? hasVibrator = await Vibration.hasVibrator();
              if (hasVibrator == true) {
                  Vibration.vibrate(pattern: [0, 40, 50, 40]); // Double tap haptic feel
              }
          }
      }
  }

  // ✅ Helper method untuk smooth rotation
  void _animateToRotation(double newRotation) {
    // Cari path terpendek (clockwise atau counter-clockwise)
    double currentRotation = rotation.value;
    double diff = newRotation - currentRotation;

    // Normalize difference to -180 to 180 (shortest path)
    if (diff > 180) {
      diff -= 360;
    } else if (diff < -180) {
      diff += 360;
    }

    targetRotation = currentRotation + diff;

    // Update tween animation
    rotationAnimation = Tween<double>(
      begin: currentRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ))..addListener(() {
      rotation.value = rotationAnimation.value % 360;
    });

    // Start animation from 0
    animationController.reset();
    animationController.forward();
  }

  // Manual refresh
  @override
  Future<void> refresh() async {
    compassSubscription?.cancel();
    await initQibla();
  }
}