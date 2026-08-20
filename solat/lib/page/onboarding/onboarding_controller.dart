import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../service/overlay_service.dart';
import '../../service/notification_service.dart';

import '../../routes/app_routes.dart';

class OnboardingController extends GetxController with WidgetsBindingObserver {
  final OverlayService _overlayService = OverlayService();
  final NotificationService _notificationService = NotificationService();
  final _storage = GetStorage();
  final PageController pageController = PageController();

  var currentPage = 0.obs;
  var hasNotificationPermission = false.obs;
  var hasLocationPermission = false.obs;
  var hasOverlayPermission = false.obs;

  var isRequestingNotification = false.obs;
  var isRequestingLocation = false.obs;
  var isRequestingOverlay = false.obs;

  var selectedGender = ''.obs; // 'male', 'female', or empty

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

      // Check overlay
      hasOverlayPermission.value = await _overlayService.hasOverlayPermission();
      debugPrint('📱 Overlay: ${hasOverlayPermission.value}');
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
      hasNotificationPermission.value = false;
      hasLocationPermission.value = false;
      hasOverlayPermission.value = false;
    }
  }

  void onPageChanged(int page) {
    currentPage.value = page;
  }

  void nextPage() {
    if (currentPage.value < 3) {
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
        }
    } catch (e) {
      debugPrint('❌ Error requesting notification permission: $e');
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
          
        } else {
        debugPrint('⚠️ Location permission denied');
        
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

        

        await Future.delayed(const Duration(milliseconds: 500));
        // nextPage() removed to fix auto-scroll bug
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