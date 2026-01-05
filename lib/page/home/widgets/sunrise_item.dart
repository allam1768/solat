import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../HomeController.dart';

class SunriseItem extends GetView<HomeController> {
  const SunriseItem({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: colorScheme.surface, // bg ikut theme
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colorScheme.surface, // border auto kebalik
          width: 1.5.w,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // spacer kiri (biar sejajar sama PrayerItem)
          SizedBox(
            width: 28.w,
            height: 28.h,
          ),

          Text(
            'Terbit',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          Obx(() => Text(
            controller.sunriseTime.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          )),
        ],
      ),
    );
  }
}
