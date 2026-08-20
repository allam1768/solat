import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:solat/core/app_colors.dart';
import '../home_controller.dart';

class PrayerItem extends GetView<HomeController> {
  final String iconPath;
  final String name;
  final String prayerKey;
  final String time;

  const PrayerItem({
    super.key,
    required this.iconPath,
    required this.name,
    required this.prayerKey,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? AppColors.white : AppColors.black;
    final activeBgColor = isDark ? AppColors.white : AppColors.black;
    final activeFgColor = isDark ? AppColors.black : AppColors.white;

    return Obx(() {
      final isActive = controller.currentPrayerKey.value == prayerKey;

      final fgColor = isActive ? activeFgColor : inactiveColor;
      final bgColor = isActive ? activeBgColor : Colors.transparent;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: bgColor,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34.w,
              height: 34.h,
              child: SvgPicture.asset(
                'assets/icons/$iconPath',
                colorFilter: ColorFilter.mode(
                  fgColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Text(
              name,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
            const Spacer(),
            Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: fgColor,
              ),
            ),
          ],
        ),
      );
    });
  }
}
