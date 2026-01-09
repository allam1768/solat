import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'SettingsController.dart';

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
                'Settings',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: 8.h),

              Text(
                'Manage your prayer reminders',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),

              SizedBox(height: 35.h),

              // ============ PERMISSIONS SECTION ============
              _buildSectionHeader('Permissions', isDark),
              SizedBox(height: 12.h),

              // All Permissions Status Card
              _buildAllPermissionsCard(context, isDark),

              SizedBox(height: 13.h),

              // Individual Permission Cards
              _buildNotificationCard(context, isDark),

              SizedBox(height: 13.h),

              _buildOverlayPermissionCard(context, isDark),

              SizedBox(height: 13.h),

              _buildBatteryOptimizationCard(context, isDark),

              SizedBox(height: 35.h),

              // ============ APP SETTINGS SECTION ============
              _buildSectionHeader('App Settings', isDark),
              SizedBox(height: 12.h),

              // Theme Setting
              _buildThemeCard(context, isDark),

              SizedBox(height: 35.h),

              // ============ TESTING SECTION ============
              _buildSectionHeader('Testing & Debug', isDark),
              SizedBox(height: 12.h),

              // Test Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildTestButton(
                      context,
                      label: 'Test Overlay',
                      icon: Icons.layers_outlined,
                      onTap: controller.testOverlayDetailed,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildTestButton(
                      context,
                      label: 'Test Notification',
                      icon: Icons.notifications_outlined,
                      onTap: controller.testNotification,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // Test All Intensities
              _buildTestButton(
                context,
                label: 'Test All Intensities (3 Levels)',
                icon: Icons.psychology_outlined,
                onTap: controller.testAllIntensities,
                isDark: isDark,
                isFullWidth: true,
              ),

              SizedBox(height: 10.h),

              // View Attempts
              _buildTestButton(
                context,
                label: 'View Prayer Attempts',
                icon: Icons.list_alt,
                onTap: controller.viewAttempts,
                isDark: isDark,
                isFullWidth: true,
              ),

              SizedBox(height: 30.h),
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
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
        letterSpacing: 0.5,
      ),
    );
  }

  // All Permissions Card
  Widget _buildAllPermissionsCard(BuildContext context, bool isDark) {
    return Obx(() {
      final allGranted = controller.hasOverlayPermission.value &&
          controller.notificationEnabled.value &&
          controller.hasBatteryExemption.value;

      return _buildSettingsCard(
        context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: allGranted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    allGranted ? Icons.check_circle : Icons.error_outline,
                    color: allGranted ? Colors.green : Colors.orange,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permission Status',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        allGranted
                            ? 'All permissions granted'
                            : 'Some permissions needed',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: allGranted
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: allGranted
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: allGranted ? Colors.green : Colors.orange,
                      width: 1.5.w,
                    ),
                  ),
                  child: Text(
                    allGranted ? 'Ready' : 'Setup',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: allGranted ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),

            // Device Warning (if problematic)
            if (controller.isProblematicDevice.value) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Detected',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Obx(() => Text(
                            controller.deviceManufacturer.value,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.orange.shade700,
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12.h),

            // Permission Summary
            _buildPermissionSummary(
              'Overlay',
              controller.hasOverlayPermission.value,
              isDark,
            ),
            SizedBox(height: 8.h),
            _buildPermissionSummary(
              'Notifications',
              controller.notificationEnabled.value,
              isDark,
            ),
            SizedBox(height: 8.h),
            _buildPermissionSummary(
              'Battery Exemption',
              controller.hasBatteryExemption.value,
              isDark,
            ),

            SizedBox(height: 16.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildActionButton(
                    label: allGranted ? 'All Set ✓' : 'Setup All',
                    icon: allGranted ? Icons.done : Icons.settings,
                    onTap: allGranted ? null : controller.requestAllPermissions,
                    isPrimary: true,
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _buildActionButton(
                    label: 'Status',
                    icon: Icons.info_outline,
                    onTap: controller.showPermissionStatus,
                    isPrimary: false,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPermissionSummary(String label, bool isGranted, bool isDark) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle : Icons.cancel,
          color: isGranted ? Colors.green : Colors.red.shade300,
          size: 16.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  // Notification Card
  Widget _buildNotificationCard(BuildContext context, bool isDark) {
    return _buildSettingsCard(
      context,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 22.sp,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Prayer time alerts',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => CustomSwitch(
            value: controller.notificationEnabled.value,
            onChanged: controller.toggleNotification,
            isDark: isDark,
          )),
        ],
      ),
    );
  }

  // Overlay Permission Card
  Widget _buildOverlayPermissionCard(BuildContext context, bool isDark) {
    return Obx(() => _buildSettingsCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.layers_outlined,
                  size: 22.sp,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overlay Permission',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Display over other apps',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: controller.hasOverlayPermission.value
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(
                    color: controller.hasOverlayPermission.value
                        ? Colors.green
                        : Colors.red,
                    width: 1.w,
                  ),
                ),
                child: Text(
                  controller.hasOverlayPermission.value ? 'Granted' : 'Denied',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: controller.hasOverlayPermission.value
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          if (!controller.hasOverlayPermission.value) ...[
            SizedBox(height: 12.h),
            _buildActionButton(
              label: 'Grant Permission',
              icon: Icons.touch_app,
              onTap: controller.requestOverlayPermission,
              isPrimary: true,
              isDark: isDark,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    ));
  }

  // Battery Optimization Card
  Widget _buildBatteryOptimizationCard(BuildContext context, bool isDark) {
    return Obx(() => _buildSettingsCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.battery_charging_full,
                  size: 22.sp,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Battery Optimization',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Allow background reminders',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                decoration: BoxDecoration(
                  color: controller.hasBatteryExemption.value
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(
                    color: controller.hasBatteryExemption.value
                        ? Colors.green
                        : Colors.orange,
                    width: 1.w,
                  ),
                ),
                child: Text(
                  controller.hasBatteryExemption.value ? 'Exempt' : 'Limited',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: controller.hasBatteryExemption.value
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (!controller.hasBatteryExemption.value) ...[
            SizedBox(height: 8.h),
            Text(
              'Recommended for reliable reminders when app is closed',
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? Colors.white60 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 12.h),
            _buildActionButton(
              label: 'Disable Optimization',
              icon: Icons.battery_full,
              onTap: controller.requestBatteryExemption,
              isPrimary: true,
              isDark: isDark,
              isFullWidth: true,
            ),
          ],
        ],
      ),
    ));
  }

  // Theme Card
  Widget _buildThemeCard(BuildContext context, bool isDark) {
    return _buildSettingsCard(
      context,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 22.sp,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isDark ? 'Dark mode' : 'Light mode',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => CustomSwitch(
            value: controller.isDarkTheme.value,
            onChanged: controller.toggleTheme,
            isDark: isDark,
          )),
        ],
      ),
    );
  }

  // Settings Card Container
  Widget _buildSettingsCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // Action Button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isPrimary,
    required bool isDark,
    bool isFullWidth = false,
  }) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: isFullWidth ? 16.w : 12.w,
        ),
        decoration: BoxDecoration(
          color: isDisabled
              ? (isDark ? Colors.white10 : Colors.black12)
              : isPrimary
              ? (isDark ? Colors.white : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: !isPrimary
              ? Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 1.5.w,
          )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isDisabled
                  ? (isDark ? Colors.white30 : Colors.black26)
                  : isPrimary
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : Colors.black),
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDisabled
                    ? (isDark ? Colors.white30 : Colors.black26)
                    : isPrimary
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Test Button
  Widget _buildTestButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required VoidCallback onTap,
        required bool isDark,
        bool isFullWidth = false,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 14.h,
          horizontal: 16.w,
        ),
        decoration: BoxDecoration(
          color: isDark ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isDark ? Colors.black : Colors.white,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Custom Switch =================

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48.w,
        height: 28.h,
        decoration: BoxDecoration(
          color: value
              ? (isDark ? Colors.white : Colors.black)
              : (isDark ? Colors.white : Colors.black).withOpacity(0.2),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: value
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white : Colors.black).withOpacity(0.3),
            width: 1.5.w,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.w,
            height: 20.h,
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            decoration: BoxDecoration(
              color: value
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : Colors.black),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}