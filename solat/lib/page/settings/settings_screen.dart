import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              // Header
              Text(
                'settings'.tr,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 24.h),

              // ============ ALERT BANNER SECTION ============
              Obx(() {
                final allGranted = controller.hasOverlayPermission.value &&
                    controller.notificationEnabled.value &&
                    controller.hasBatteryExemption.value;

                if (allGranted) {
                  return const SizedBox
                      .shrink(); // Menyembunyikan banner jika semua izin aman
                }

                return Column(
                  children: [
                    _buildAlertBanner(context, isDark),
                    SizedBox(height: 30.h),
                  ],
                );
              }),

              // ============ APP SETTINGS SECTION ============
              _buildSectionHeader('preferences'.tr, isDark),
              SizedBox(height: 12.h),

              // Theme Setting
              _buildThemeCard(context, isDark),

              // Language Setting
              SizedBox(height: 12.h),
              _buildLanguageCard(context, isDark),

              // ============ SMART REMINDER SECTION ============
              SizedBox(height: 30.h),
              _buildSectionHeader('smart_reminder'.tr, isDark),
              SizedBox(height: 12.h),
              _buildSmartReminderCards(context, isDark),

              // Device Specific Information
              Obx(() {
                if (controller.isProblematicDevice.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20.h),
                      _buildSectionHeader('device_specific'.tr, isDark),
                      SizedBox(height: 12.h),
                      _buildDeviceWarningCard(context, isDark),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),

              // ============ SUPPORT SECTION ============
              SizedBox(height: 30.h),
              _buildSectionHeader('support_feedback'.tr, isDark),
              SizedBox(height: 12.h),
              _buildFeedbackCard(context, isDark),
              SizedBox(height: 40.h), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BUILDERS ====================

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }

  // Modern Alert Banner - Black & White Theme
  Widget _buildAlertBanner(BuildContext context, bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final bgColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200;
    final borderColor = isDark ? Colors.white30 : Colors.black26;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.requestAllPermissions,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: borderColor,
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: fgColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'action_required'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: fgColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'setup_permissions'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: fgColor.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: fgColor,
                size: 24.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Theme Card - Black & White Theme
  Widget _buildThemeCard(BuildContext context, bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white30 : Colors.black12;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: borderColor,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 20.sp,
              color: fgColor,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dark_mode'.tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'switch_theme'.tr,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: fgColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Obx(() => Switch.adaptive(
                value: controller.isDarkTheme.value,
                onChanged: controller.toggleTheme,
                activeColor: Colors.black,
                activeTrackColor: Colors.grey.shade400,
              )),
        ],
      ),
    );
  }

  // Smart Reminder Profile Section - Elegant Redesign
  Widget _buildSmartReminderCards(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildProfileCard(
          index: 0,
          title: 'basic'.tr,
          subtitle: 'basic_subtitle'.tr,
          description: 'basic_desc'.tr,
          isDark: isDark,
        ),
        SizedBox(height: 12.h),
        _buildProfileCard(
          index: 1,
          title: 'smart'.tr,
          subtitle: 'balanced_system'.tr,
          description: 'smart_desc'.tr,
          isRecommended: true,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required int index,
    required String title,
    required String subtitle,
    required String description,
    bool isRecommended = false,
    required bool isDark,
  }) {
    return Obx(() {
      final isSelected = controller.reminderProfile.value == index;
      final fgColor = isDark ? Colors.white : Colors.black;
      final invertedColor = isDark ? Colors.black : Colors.white;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          color: isSelected ? fgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            onTap: () => controller.setReminderProfile(index),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? fgColor : fgColor.withValues(alpha: 0.1),
                  width: 2.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: isSelected ? invertedColor : fgColor,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isSelected
                                  ? invertedColor.withValues(alpha: 0.7)
                                  : fgColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      if (isRecommended && !isSelected)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: fgColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'recommended'.tr,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              color: fgColor,
                            ),
                          ),
                        )
                      else if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: invertedColor,
                          size: 24.sp,
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: isSelected
                          ? invertedColor.withValues(alpha: 0.8)
                          : fgColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Language Selection Card
  Widget _buildLanguageCard(BuildContext context, bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white30 : Colors.black12;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: borderColor,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.language_rounded,
              size: 20.sp,
              color: fgColor,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'language'.tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Obx(() {
                  String langName = 'English';
                  if (controller.languageCode.value == 'id') langName = 'Bahasa Indonesia';
                  return Text(
                    langName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: fgColor.withValues(alpha: 0.6),
                    ),
                  );
                }),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showLanguagePicker(context, isDark),
            child: Text(
              'Change',
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.black : Colors.white;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border(
              top: BorderSide(color: fgColor.withValues(alpha: 0.1), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
            SizedBox(height: 20.h),
            _buildLanguageItem('English', 'en', 'US', isDark),
            _buildLanguageItem('Bahasa Indonesia', 'id', 'ID', isDark),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(
      String name, String code, String country, bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;

    return Obx(() {
      final isSelected = controller.languageCode.value == code;
      return ListTile(
        onTap: () {
          controller.changeLanguage(code, country);
          Get.back();
        },
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? fgColor : fgColor.withValues(alpha: 0.3),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: fgColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    });
  }

  // Device Warning Card - Black & White Theme
  Widget _buildDeviceWarningCard(BuildContext context, bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white30 : Colors.black12;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: borderColor,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.phonelink_setup,
            color: fgColor,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device: ${controller.deviceManufacturer.value}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your device may need special settings to run properly in the background.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: fgColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Feedback Card - Black & White Theme
  Widget _buildFeedbackCard(BuildContext context, bool isDark) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white30 : Colors.black12;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.launchFeedback,
        borderRadius: BorderRadius.circular(15.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(
              color: borderColor,
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: fgColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20.sp,
                  color: fgColor,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'feedback'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: fgColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'feedback_desc'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: fgColor.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.launch_rounded,
                color: fgColor.withValues(alpha: 0.3),
                size: 18.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
