import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../service/OverlayService.dart';
import '../../service/NotificationService.dart';
import '../../service/PermissionHelper.dart';
import '../../routes/app_routes.dart';

class OnboardingController extends GetxController with WidgetsBindingObserver {
  final OverlayService _overlayService = OverlayService();
  final NotificationService _notificationService = NotificationService();
  final PermissionHelper _permissionHelper = PermissionHelper();
  final _storage = GetStorage();

  final PageController pageController = PageController();

  var currentPage = 0.obs;
  var hasNotificationPermission = false.obs;
  var hasLocationPermission = false.obs;
  var hasBatteryExemption = false.obs;
  var hasOverlayPermission = false.obs;

  var isRequestingNotification = false.obs;
  var isRequestingLocation = false.obs;
  var isRequestingBattery = false.obs;
  var isRequestingOverlay = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ✅ KUNCI: Saat app kembali dari background (Settings), reset loading & re-check
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 App resumed, checking permissions...');

      // Reset semua loading states
      isRequestingNotification.value = false;
      isRequestingLocation.value = false;
      isRequestingBattery.value = false;
      isRequestingOverlay.value = false;

      // Re-check semua permissions
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    try {
      // Check notification
      hasNotificationPermission.value = _notificationService.isNotificationEnabled();
      debugPrint('🔔 Notification: ${hasNotificationPermission.value}');

      // Check location
      final locationStatus = await Permission.location.status;
      hasLocationPermission.value = locationStatus.isGranted;
      debugPrint('📍 Location: ${hasLocationPermission.value}');

      // Check battery permission
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      hasBatteryExemption.value = batteryStatus.isGranted;
      debugPrint('🔋 Battery: ${hasBatteryExemption.value}');

      // Check overlay
      hasOverlayPermission.value = await _overlayService.hasOverlayPermission();
      debugPrint('📱 Overlay: ${hasOverlayPermission.value}');
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      hasNotificationPermission.value = false;
      hasLocationPermission.value = false;
      hasBatteryExemption.value = false;
      hasOverlayPermission.value = false;
    }
  }

  void onPageChanged(int page) {
    currentPage.value = page;
  }

  void nextPage() {
    if (currentPage.value < 5) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> requestNotificationPermission() async {
    if (isRequestingNotification.value) return;

    isRequestingNotification.value = true;
    debugPrint('📱 Requesting notification permission...');

    try {
      await _notificationService.setNotificationEnabled(true);

      await Future.delayed(const Duration(milliseconds: 500));
      hasNotificationPermission.value = _notificationService.isNotificationEnabled();

      if (hasNotificationPermission.value) {
        debugPrint('✅ Notification permission granted');
        Fluttertoast.showToast(
          msg: "Notification permission granted",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.black,
          fontSize: 16.0,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        nextPage();
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
      Fluttertoast.showToast(
        msg: "Failed to request notification permission",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey.shade400,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } finally {
      isRequestingNotification.value = false;
    }
  }

  Future<void> requestLocationPermission() async {
    if (isRequestingLocation.value) return;

    isRequestingLocation.value = true;
    debugPrint('📍 Requesting location permission...');

    try {
      final status = await Permission.location.request();

      await Future.delayed(const Duration(milliseconds: 500));
      hasLocationPermission.value = status.isGranted;

      if (hasLocationPermission.value) {
        debugPrint('✅ Location permission granted');
        Fluttertoast.showToast(
          msg: "Location permission granted",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.black,
          fontSize: 16.0,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        nextPage();
      } else {
        debugPrint('⚠️ Location permission denied');
        Fluttertoast.showToast(
          msg: "Location access helps calculate accurate prayer times",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade300,
          textColor: Colors.black,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      Fluttertoast.showToast(
        msg: "Failed to request location permission",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey.shade400,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } finally {
      isRequestingLocation.value = false;
    }
  }

  Future<void> requestBatteryExemption() async {
    if (isRequestingBattery.value) return;

    isRequestingBattery.value = true;
    debugPrint('🔋 Requesting battery exemption...');

    try {
      final status = await Permission.ignoreBatteryOptimizations.request();

      debugPrint('🔋 Battery status after request: $status');

      await Future.delayed(const Duration(milliseconds: 500));

      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      hasBatteryExemption.value = batteryStatus.isGranted;

      debugPrint('🔋 Battery exemption: ${hasBatteryExemption.value}');

      if (hasBatteryExemption.value) {
        debugPrint('✅ Battery exemption granted');
        Fluttertoast.showToast(
          msg: "Battery optimization disabled",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.black,
          fontSize: 16.0,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        nextPage();
      } else {
        debugPrint('⚠️ Battery exemption denied or needs manual action');
        Fluttertoast.showToast(
          msg: "Please disable battery optimization manually in settings",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade300,
          textColor: Colors.black,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      debugPrint('❌ Error requesting battery exemption: $e');
      Fluttertoast.showToast(
        msg: "Failed to request battery exemption",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey.shade400,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    } finally {
      isRequestingBattery.value = false;
    }
  }

  Future<void> requestOverlayPermission() async {
    if (isRequestingOverlay.value) return;

    isRequestingOverlay.value = true;
    debugPrint('📱 Requesting overlay permission...');

    try {
      // Check dulu
      final alreadyGranted = await _overlayService.hasOverlayPermission();
      if (alreadyGranted) {
        debugPrint('✅ Overlay already granted');
        hasOverlayPermission.value = true;
        isRequestingOverlay.value = false;

        Fluttertoast.showToast(
          msg: "Overlay permission already granted",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey.shade200,
          textColor: Colors.black,
          fontSize: 16.0,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        nextPage();
        return;
      }

      // Buka Settings
      debugPrint('📱 Opening overlay settings...');
      await _overlayService.requestOverlayPermission();

      debugPrint('📱 Settings request sent, user will go to Settings...');

      // ✅ PENTING: Jangan reset loading di sini, biar didChangeAppLifecycleState yang handle

    } catch (e) {
      debugPrint('❌ Error requesting overlay permission: $e');
      isRequestingOverlay.value = false;

      Fluttertoast.showToast(
        msg: "Failed to open settings: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.grey.shade400,
        textColor: Colors.black,
        fontSize: 16.0,
      );
    }
  }

  Future<void> completeOnboarding() async {
    try {
      await _storage.write('onboarding_completed', true);
      debugPrint('✅ Onboarding completed');
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAllNamed(AppRoutes.MAIN);
    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
      Get.offAllNamed(AppRoutes.MAIN);
    }
  }

  void skipOnboarding() async {
    try {
      await _storage.write('onboarding_completed', true);
      debugPrint('⏭️ Onboarding skipped');
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAllNamed(AppRoutes.MAIN);
    } catch (e) {
      debugPrint('❌ Error skipping onboarding: $e');
      Get.offAllNamed(AppRoutes.MAIN);
    }
  }
}