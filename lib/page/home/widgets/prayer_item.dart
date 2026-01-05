import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../../../core/app_colors.dart';
import '../HomeController.dart';

class PrayerItem extends GetView<HomeController> {
  final String iconPath;
  final String name;
  final String time;

  const PrayerItem({
    super.key,
    required this.iconPath,
    required this.name,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool isActive = controller.currentPrayerName.value == name;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 2.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 32.w,
              height: 32.h,
              child: SvgPicture.asset(
                'assets/icons/$iconPath',
                color: AppColors.primary,
              ),
            ),
            Text(
              name,
              style: TextStyle(
                fontSize: isActive ? 18.sp : 16.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? AppColors.primary : Colors.black87,
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: isActive ? 18.sp : 16.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      );
    });
  }
}