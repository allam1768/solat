import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import 'settings_controller.dart';
import 'widgets/settings_alert_banner.dart';
import 'widgets/settings_section_header.dart';
import 'widgets/settings_smart_reminder_cards.dart';
import 'widgets/settings_toggle_card.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 16.h,
            bottom: 100.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              // Header
              Text(
                'pengaturan',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              SizedBox(height: 24.h),

              // Alert Banner Section
              Obx(() {
                final allGranted = controller.hasOverlayPermission.value;

                if (allGranted) return const SizedBox.shrink();

                return Column(
                  children: [
                    SettingsAlertBanner(controller: controller, isDark: isDark),
                    SizedBox(height: 30.h),
                  ],
                );
              }),

              // General Settings (Theme, Friday Reminder)
              Obx(() => SettingsToggleCard(
                    title: 'mode gelap',
                    subtitle: 'ubah tema aplikasi',
                    iconPath: isDark
                        ? 'assets/icons/isya.svg'
                        : 'assets/icons/zuhur.svg',
                    value: controller.isDarkTheme.value,
                    onChanged: controller.toggleTheme,
                    isDark: isDark,
                  )),
              SizedBox(height: 12.h),
              Obx(() => SettingsToggleCard(
                    title: 'pengingat Jumat',
                    subtitle: 'ingatkan 50 & 30 menit sebelum Jumatan.',
                    iconPath: 'assets/icons/juamtan_icon.svg',
                    value: controller.fridayReminderEnabled.value,
                    onChanged: controller.toggleFridayReminder,
                    isDark: isDark,
                  )),

              // Smart Reminder Section
              SizedBox(height: 30.h),
              SettingsSectionHeader(title: 'tipe pengingat', isDark: isDark),
              SizedBox(height: 12.h),
              SettingsSmartReminderCards(
                  controller: controller, isDark: isDark),

              SizedBox(height: 40.h),

              // Footer Version & Privacy Policy
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => controller.checkManualUpdate(),
                      child: Text(
                        'versi ${controller.appVersion}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      '  |  ',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.PRIVACY_POLICY),
                      child: Text(
                        'Privacy Policy ↗',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
