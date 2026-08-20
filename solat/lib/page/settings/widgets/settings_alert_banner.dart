import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solat/core/app_colors.dart';
import '../settings_controller.dart';

class SettingsAlertBanner extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;

  const SettingsAlertBanner({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isDark ? AppColors.lightGrey : AppColors.darkGrey;
    final cardColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? AppColors.background : AppColors.black;

    return GestureDetector(
      onTap: controller.requestAllPermissions,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: borderColor,
            width: 4.w,
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
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.warning_amber_rounded,
                color: fgColor,
                size: 34.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'perlu izin tambahan',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: borderColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Tap untuk atur izin pengingat.',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: fgColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
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
    );
  }
}
