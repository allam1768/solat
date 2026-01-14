import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'OnboardingController.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PageView(
          controller: controller.pageController,
          onPageChanged: controller.onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildWelcomePage(),
            _buildNotificationPermissionPage(),
            _buildLocationPermissionPage(),
            _buildBatteryOptimizationPage(),
            _buildOverlayPermissionPage(),
            _buildCompletePage(),
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

          // App Icon/Illustration
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
            'Welcome to Solat',
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

          _buildNextButton('Get Started', () => controller.nextPage()),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  // Page 2: Notification Permission
  Widget _buildNotificationPermissionPage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),

          _buildProgressIndicator(1, 4),

          SizedBox(height: 40.h),

          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 50.sp,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 32.h),

          Text(
            'Prayer Notifications',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 16.h),

          Text(
            'Receive timely alerts for all five daily prayers',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          SizedBox(height: 32.h),

          _buildFeatureItem(
            Icons.alarm,
            'Never miss a prayer',
            'Get notified before each prayer time',
          ),


          const Spacer(),

          Obx(() => _buildPermissionStatus(
            'Notification Permission',
            controller.hasNotificationPermission.value,
            controller.isRequestingNotification.value,
          )),

          SizedBox(height: 16.h),

          Obx(() {
            if (controller.hasNotificationPermission.value) {
              return _buildNextButton('Continue', () => controller.nextPage());
            } else {
              return Column(
                children: [
                  _buildPrimaryButton(
                    'Enable Notifications',
                    controller.isRequestingNotification.value
                        ? null
                        : () => controller.requestNotificationPermission(),
                    isLoading: controller.isRequestingNotification.value,
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

  // Page 3: Location Permission
  Widget _buildLocationPermissionPage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),

          _buildProgressIndicator(2, 4),

          SizedBox(height: 40.h),

          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 50.sp,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 32.h),

          Text(
            'Location Access',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 16.h),

          Text(
            'We need your location to calculate accurate prayer times for your area',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          SizedBox(height: 32.h),

          _buildFeatureItem(
            Icons.my_location,
            'Accurate prayer times',
            'Get precise timings based on your location',
          ),

          SizedBox(height: 16.h),

          _buildFeatureItem(
            Icons.update,
            'Auto-update',
            'Prayer times adjust automatically when you travel',
          ),

          const Spacer(),

          Obx(() => _buildPermissionStatus(
            'Location Permission',
            controller.hasLocationPermission.value,
            controller.isRequestingLocation.value,
          )),

          SizedBox(height: 16.h),

          Obx(() {
            if (controller.hasLocationPermission.value) {
              return _buildNextButton('Continue', () => controller.nextPage());
            } else {
              return Column(
                children: [
                  _buildPrimaryButton(
                    'Grant Location Access',
                    controller.isRequestingLocation.value
                        ? null
                        : () => controller.requestLocationPermission(),
                    isLoading: controller.isRequestingLocation.value,
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

  // Page 4: Battery Optimization
  Widget _buildBatteryOptimizationPage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),

          _buildProgressIndicator(3, 4),

          SizedBox(height: 40.h),

          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.battery_charging_full,
              size: 50.sp,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 32.h),

          Text(
            'Battery Optimization',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 16.h),

          Text(
            'Disable battery optimization to ensure reminders work even when the app is closed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          SizedBox(height: 32.h),

          _buildFeatureItem(
            Icons.access_time,
            'Reliable reminders',
            'Prayer alerts will work even in background',
          ),

          SizedBox(height: 16.h),

          _buildFeatureItem(
            Icons.battery_saver,
            'Optimized performance',
            'Minimal battery usage while staying active',
          ),

          const Spacer(),

          Obx(() => _buildPermissionStatus(
            'Battery Exemption',
            controller.hasBatteryExemption.value,
            controller.isRequestingBattery.value,
          )),

          SizedBox(height: 16.h),

          Obx(() {
            if (controller.hasBatteryExemption.value) {
              return _buildNextButton('Continue', () => controller.nextPage());
            } else {
              return Column(
                children: [
                  _buildPrimaryButton(
                    'Disable Optimization',
                    controller.isRequestingBattery.value
                        ? null
                        : () => controller.requestBatteryExemption(),
                    isLoading: controller.isRequestingBattery.value,
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

  // Page 5: Overlay Permission
  Widget _buildOverlayPermissionPage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),

          _buildProgressIndicator(4, 4),

          SizedBox(height: 40.h),

          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.layers_outlined,
              size: 50.sp,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 32.h),

          Text(
            'Display Over Apps',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: 16.h),

          Text(
            'This permission allows us to show prayer reminders even when you\'re using other apps',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black54,
              height: 1.5,
            ),
          ),

          SizedBox(height: 32.h),

          _buildFeatureItem(
            Icons.phone_android,
            'Works on any screen',
            'Get reminders while browsing, gaming, or watching videos',
          ),

          SizedBox(height: 16.h),

          _buildFeatureItem(
            Icons.touch_app,
            'Quick action',
            'Mark prayer as done with one tap',
          ),

          const Spacer(),

          Obx(() => _buildPermissionStatus(
            'Overlay Permission',
            controller.hasOverlayPermission.value,
            controller.isRequestingOverlay.value,
          )),

          SizedBox(height: 16.h),

          Obx(() {
            if (controller.hasOverlayPermission.value) {
              return _buildNextButton('Continue', () => controller.nextPage());
            } else {
              return Column(
                children: [
                  _buildPrimaryButton(
                    'Grant Permission',
                    controller.isRequestingOverlay.value
                        ? null
                        : () => controller.requestOverlayPermission(),
                    isLoading: controller.isRequestingOverlay.value,
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
                  ? 'You\'re ready to start using Solat!\nNever miss a prayer time again.'
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

          // Summary
          Obx(() => Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildSummaryItem('Notifications', controller.hasNotificationPermission.value),
                Divider(height: 20.h, color: Colors.grey.shade300),
                _buildSummaryItem('Location', controller.hasLocationPermission.value),
                Divider(height: 20.h, color: Colors.grey.shade300),
                _buildSummaryItem('Battery', controller.hasBatteryExemption.value),
                Divider(height: 20.h, color: Colors.grey.shade300),
                _buildSummaryItem('Overlay', controller.hasOverlayPermission.value),
              ],
            ),
          )),

          const Spacer(),

          _buildNextButton('Start Using Solat', () => controller.completeOnboarding()),

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
        borderRadius: BorderRadius.circular(8.r),
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

  Widget _buildNextButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback? onTap, {bool isLoading = false}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey.shade400 : Colors.black,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: isLoading
            ? Center(
          child: SizedBox(
            width: 20.w,
            height: 20.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        )
            : Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return InkWell(
      onTap: () => controller.nextPage(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5.w),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          'Skip for now',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}