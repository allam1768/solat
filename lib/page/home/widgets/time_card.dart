import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/app_colors.dart';
import '../HomeController.dart';

class TimeCard extends GetView<HomeController> {
  const TimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 30.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Obx(() => Text(
                  controller.currentTime.value,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w600,
                  ),
                )),
                Transform.translate(
                  offset: Offset(-60.w, 0),
                  child: Icon(
                    Icons.access_time_rounded,
                    size: 30.sp,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Obx(() => Text(
            '${controller.currentDay.value}, ${controller.currentDate.value}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          )),
        ],
      ),
    );
  }
}