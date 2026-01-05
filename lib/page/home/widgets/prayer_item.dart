import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final isActive = controller.currentPrayerName.value == name;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.onSurface.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive ? colorScheme.onSurface : Colors.transparent,
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
                colorFilter: ColorFilter.mode(
                  colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
            Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: isActive ? 18.sp : 16.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive
                    ? colorScheme.onSurface
                    : colorScheme.onSurface,
              ),
            ),
            Text(
              time,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: isActive ? 18.sp : 16.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive
                    ? colorScheme.onSurface
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    });
  }
}
