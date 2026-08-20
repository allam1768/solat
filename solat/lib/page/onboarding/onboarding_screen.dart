import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'onboarding_controller.dart';
import 'widgets/onboarding_welcome_view.dart';
import 'widgets/onboarding_permission_view.dart';
import 'widgets/onboarding_progress_indicator.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                const OnboardingWelcomeView(),
                OnboardingPermissionView(
                  pageIndex: 1,
                  imagePath: 'assets/images/notif_izin.png',
                  imageHeight: 334.h,
                  title: 'biar nggak terlewat',
                  subtitle:
                      'kami akan kirim notifikasi tiap kali waktu sholat tiba.',
                  isGrantedRx: controller.hasNotificationPermission,
                  isLoadingRx: controller.isRequestingNotification,
                  onRequest: controller.requestNotificationPermission,
                  actionLabel: 'izinkan',
                ),
                OnboardingPermissionView(
                  pageIndex: 2,
                  imagePath: 'assets/images/lokasi_izin.png',
                  imageHeight: 160.h,
                  title: 'cek posisimu sekarang',
                  subtitle:
                      'jadwal sholat bakal otomatis ngikutin di mana pun kamu berada.',
                  isGrantedRx: controller.hasLocationPermission,
                  isLoadingRx: controller.isRequestingLocation,
                  onRequest: controller.requestLocationPermission,
                  actionLabel: 'izinkan',
                ),
                OnboardingPermissionView(
                  pageIndex: 3,
                  title: 'pengingat selalu hadir',
                  imagePath: 'assets/images/overlay_izin.png',
                  imageHeight: 367.h,
                  subtitle:
                      'pengingat tetap muncul walau kamu lagi asyik buka aplikasi lain.',
                  isGrantedRx: controller.hasOverlayPermission,
                  isLoadingRx: controller.isRequestingOverlay,
                  onRequest: controller.requestOverlayPermission,
                  actionLabel: 'izinkan',
                  grantedActionLabel: 'yuk, mulai !',
                  isLastPage: true,
                ),
              ],
            ),
            Obx(() {
              final page = controller.currentPage.value;
              if (page > 0 && page < 4) {
                return Positioned(
                  top: 24.w + 40.h,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: OnboardingProgressIndicator(current: page, total: 3),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
