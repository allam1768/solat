import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../home_controller.dart';

class TimeCard extends GetView<HomeController> {
  const TimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 110.h,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: colorScheme.onSurface,
          width: 1.5.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Obx(() => Row(
                  mainAxisSize: MainAxisSize.min, // 🔑 row ikut isi
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 20.sp,
                      color: colorScheme.onSurface,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      controller.currentTime.value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 24.sp,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                )),
          ),
          SizedBox(height: 20.h),
          Obx(() => Text(
                '${controller.currentDay.value}, ${controller.currentDate.value}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 20.sp,
                  color: colorScheme.onSurface,
                ),
              )),
        ],
      ),
    );
  }
}
