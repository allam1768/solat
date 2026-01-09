import 'dart:async';
import 'dart:math';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaController extends GetxController {
  var rotation = 0.0.obs;
  var qiblaDirection = 0.0.obs;
  var phoneHeading = 0.0.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var locationName = ''.obs;

  StreamSubscription<CompassEvent>? compassSubscription;

  // Koordinat Ka'bah, Makkah
  final double makkahLat = 21.4225;
  final double makkahLng = 39.8262;

  @override
  void onInit() {
    super.onInit();
    initQibla();
  }

  @override
  void onClose() {
    compassSubscription?.cancel();
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

        rotation.value = needleRotation;
      }
    });
  }

  // Manual refresh
  Future<void> refresh() async {
    compassSubscription?.cancel();
    await initQibla();
  }
}