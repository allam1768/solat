import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'onboarding_controller.dart';

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
                _buildWelcomePage(),
                _buildGenderPage(),
                _buildPermissionPage(
                  pageIndex: 2,
                  icon: Icons.notifications_active_outlined,
                  title: 'Prayer Notifications',
                  subtitle: 'Receive timely alerts for all five daily prayers',
                  feature1Icon: Icons.alarm,
                  feature1Title: 'Never miss a prayer',
                  feature1Subtitle: 'Get notified before each prayer time',
                  permissionLabel: 'Notification Permission',
                  isGrantedRx: controller.hasNotificationPermission,
                  isLoadingRx: controller.isRequestingNotification,
                  onRequest: controller.requestNotificationPermission,
                  actionLabel: 'Enable Notifications',
                ),
                _buildPermissionPage(
                  pageIndex: 3,
                  icon: Icons.location_on_outlined,
                  title: 'Location Access',
                  subtitle:
                      'We need your location to calculate accurate prayer times for your area',
                  feature1Icon: Icons.my_location,
                  feature1Title: 'Accurate prayer times',
                  feature1Subtitle:
                      'Get precise timings based on your location',
                  feature2Icon: Icons.update,
                  feature2Title: 'Auto-update',
                  feature2Subtitle:
                      'Prayer times adjust automatically when you travel',
                  permissionLabel: 'Location Permission',
                  isGrantedRx: controller.hasLocationPermission,
                  isLoadingRx: controller.isRequestingLocation,
                  onRequest: controller.requestLocationPermission,
                  actionLabel: 'Grant Location Access',
                ),
                _buildPermissionPage(
                  pageIndex: 4,
                  icon: Icons.battery_charging_full,
                  title: 'Battery Optimization',
                  subtitle:
                      'Disable battery optimization to ensure reminders work even when the app is closed',
                  feature1Icon: Icons.access_time,
                  feature1Title: 'Reliable reminders',
                  feature1Subtitle:
                      'Prayer alerts will work even in background',
                  feature2Icon: Icons.battery_saver,
                  feature2Title: 'Optimized performance',
                  feature2Subtitle:
                      'Minimal battery usage while staying active',
                  permissionLabel: 'Battery Exemption',
                  isGrantedRx: controller.hasBatteryExemption,
                  isLoadingRx: controller.isRequestingBattery,
                  onRequest: controller.requestBatteryExemption,
                  actionLabel: 'Disable Optimization',
                ),
                _buildPermissionPage(
                  pageIndex: 5,
                  icon: Icons.layers_outlined,
                  title: 'Display Over Apps',
                  subtitle:
                      'This permission allows us to show prayer reminders even when you\'re using other apps',
                  feature1Icon: Icons.phone_android,
                  feature1Title: 'Works on any screen',
                  feature1Subtitle:
                      'Get reminders while browsing, gaming, or watching videos',
                  feature2Icon: Icons.touch_app,
                  feature2Title: 'Quick action',
                  feature2Subtitle: 'Mark prayer as done with one tap',
                  permissionLabel: 'Overlay Permission',
                  isGrantedRx: controller.hasOverlayPermission,
                  isLoadingRx: controller.isRequestingOverlay,
                  onRequest: controller.requestOverlayPermission,
                  actionLabel: 'Grant Permission',
                ),
                _buildCompletePage(),
              ],
            ),
            Obx(() {
              if (controller.currentPage.value > 0 &&
                  controller.currentPage.value < 6) {
                return Positioned(
                  top: 24.w + 40.h,
                  left: 0,
                  right: 0,
                  child:
                      _buildProgressIndicator(controller.currentPage.value, 5),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  // Page 1: Welcome
  Widget _buildWelcomePage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/logo.svg',
                width: 60.sp,
                height: 60.sp,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'Welcome to Salat',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Never miss your prayer times with\nsmart reminders and overlay alerts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const Spacer(),
          _buildPrimaryButton('Get Started', () => controller.nextPage()),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // Page 1: Gender Selection
  Widget _buildGenderPage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 100.h),
          Text(
            'Select Your Gender',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'This helps us personalize your experience',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 48.h),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildGenderOption(
                      'Male',
                      Icons.male,
                      controller.selectedGender.value == 'male',
                      () => controller.selectedGender.value = 'male',
                    )),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Obx(() => _buildGenderOption(
                      'Female',
                      Icons.female,
                      controller.selectedGender.value == 'female',
                      () => controller.selectedGender.value = 'female',
                    )),
              ),
            ],
          ),
          const Spacer(),
          Obx(() => _buildPrimaryButton(
                'Continue',
                controller.selectedGender.value.isEmpty
                    ? null
                    : () => controller.nextPage(),
              )),
          SizedBox(height: 12.h),
          _buildSkipButton(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildGenderOption(
      String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: 2.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48.sp,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generic Builder for Permission Pages
  Widget _buildPermissionPage({
    required int pageIndex,
    required IconData icon,
    required String title,
    required String subtitle,
    required IconData feature1Icon,
    required String feature1Title,
    required String feature1Subtitle,
    IconData? feature2Icon,
    String? feature2Title,
    String? feature2Subtitle,
    required String permissionLabel,
    required RxBool isGrantedRx,
    required RxBool isLoadingRx,
    required VoidCallback onRequest,
    required String actionLabel,
  }) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          SizedBox(height: 8.h), // Placeholder for static progress indicator
          SizedBox(height: 40.h),
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50.sp, color: Colors.black87),
          ),
          SizedBox(height: 32.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          _buildFeatureItem(feature1Icon, feature1Title, feature1Subtitle),
          if (feature2Icon != null &&
              feature2Title != null &&
              feature2Subtitle != null) ...[
            SizedBox(height: 16.h),
            _buildFeatureItem(feature2Icon, feature2Title, feature2Subtitle),
          ],
          const Spacer(),
          Obx(() => _buildPermissionStatus(
                permissionLabel,
                isGrantedRx.value,
                isLoadingRx.value,
              )),
          SizedBox(height: 16.h),
          Obx(() {
            if (isGrantedRx.value) {
              return _buildPrimaryButton(
                  'Continue', () => controller.nextPage());
            } else {
              return Column(
                children: [
                  _buildPrimaryButton(
                    actionLabel,
                    isLoadingRx.value ? null : onRequest,
                    isLoading: isLoadingRx.value,
                  ),
                  SizedBox(height: 12.h),
                  _buildSkipButton(),
                ],
              );
            }
          }),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // Page 6: Complete
  Widget _buildCompletePage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 60.sp,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'All Set!',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Obx(() {
            final allGranted = controller.hasNotificationPermission.value &&
                controller.hasLocationPermission.value &&
                controller.hasBatteryExemption.value &&
                controller.hasOverlayPermission.value;

            return Text(
              allGranted
                  ? 'You\'re ready to start using Salat!\nNever miss a prayer time again.'
                  : 'You can start using the app now.\nSome features may require additional permissions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.black54,
                height: 1.5,
              ),
            );
          }),
          SizedBox(height: 32.h),
          Obx(() => Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildSummaryItem('Notifications',
                        controller.hasNotificationPermission.value),
                    Divider(height: 20.h, color: Colors.grey.shade300),
                    _buildSummaryItem(
                        'Location', controller.hasLocationPermission.value),
                    Divider(height: 20.h, color: Colors.grey.shade300),
                    _buildSummaryItem(
                        'Battery', controller.hasBatteryExemption.value),
                    Divider(height: 20.h, color: Colors.grey.shade300),
                    _buildSummaryItem(
                        'Overlay', controller.hasOverlayPermission.value),
                  ],
                ),
              )),
          const Spacer(),
          _buildPrimaryButton(
              'Start Using Salat', () => controller.completeOnboarding()),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildProgressIndicator(int current, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: index == current - 1 ? 24.w : 8.w,
          height: 8.h,
          decoration: BoxDecoration(
            color: index == current - 1 ? Colors.black : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: 24.sp, color: Colors.black87),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionStatus(String label, bool isGranted, bool isLoading) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isGranted ? Colors.grey.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: isGranted ? Colors.black : Colors.grey.shade400,
          width: 1.5.w,
        ),
      ),
      child: Row(
        children: [
          if (isLoading)
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          else
            Icon(
              isGranted ? Icons.check_circle : Icons.info_outline,
              color: isGranted ? Colors.black : Colors.grey.shade600,
              size: 20.sp,
            ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              isGranted ? '$label granted' : '$label needed',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isGranted ? Colors.black : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, bool isGranted) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle : Icons.cancel,
          color: isGranted ? Colors.black : Colors.grey.shade400,
          size: 20.sp,
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          isGranted ? 'Granted' : 'Skipped',
          style: TextStyle(
            fontSize: 12.sp,
            color: isGranted ? Colors.black : Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback? onTap,
      {bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.black, width: 1.5.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
        onPressed: () => controller.nextPage(),
        child: Text(
          'Skip for now',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
