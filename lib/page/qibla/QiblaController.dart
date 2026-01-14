import 'dart:async';
import 'dart:math';
import 'package:flutter/animation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaController extends GetxController with GetSingleTickerProviderStateMixin {
  var rotation = 0.0.obs;
  var qiblaDirection = 0.0.obs;
  var phoneHeading = 0.0.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var locationName = ''.obs;

  StreamSubscription<CompassEvent>? compassSubscription;

  // ✅ ANIMATION - Untuk smooth rotation
  late AnimationController animationController;
  late Animation<double> rotationAnimation;
  double targetRotation = 0.0;

  // Koordinat Ka'bah, Makkah
  final double makkahLat = 21.4225;
  final double makkahLng = 39.8262;

  @override
  void onInit() {
    super.onInit();

    // ✅ Setup animation controller (300ms duration, adjust sesuai selera)
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // Smooth tapi responsive
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

    initQibla();
  }

  @override
  void onClose() {
    compassSubscription?.cancel();
    animationController.dispose(); // ✅ Don't forget to dispose
    super.onClose();
  }

  Future<void> initQibla() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check & request permissions
      await requestPermissions();

      // Get user location
      Position position = await getCurrentLocation();

      // Calculate qibla direction
      double qibla = calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );
      qiblaDirection.value = qibla;

      // Get location name (optional)
      locationName.value = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

      // Start listening to compass
      listenToCompass();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = e.toString();
      print('Error init qibla: $e');
    }
  }

  Future<void> requestPermissions() async {
    // Request location permission menggunakan Geolocator
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled. Please enable GPS');
    }
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
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

        // Calculate rotation: jarum harus selalu menunjuk ke kiblat
        // Formula: qiblaDirection - phoneHeading
        double needleRotation = qiblaDirection.value - phoneHeading.value;

        // Normalize to 0-360 untuk support semua case
        needleRotation = needleRotation % 360;
        if (needleRotation < 0) {
          needleRotation += 360;
        }

        // ✅ SMOOTH ANIMATION - Animate dari current ke target
        _animateToRotation(needleRotation);
      }
    });
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
  Future<void> refresh() async {
    compassSubscription?.cancel();
    await initQibla();
  }
}