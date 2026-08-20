import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:solat/core/app_colors.dart';
import '../home_controller.dart';

class TimeCard extends GetView<HomeController> {
  const TimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.white : AppColors.black;
    final cardColor = isDark ? AppColors.black : AppColors.white;
    final primaryTextColor = isDark ? AppColors.white : AppColors.black;
    final secondaryTextColor = isDark ? AppColors.lightGrey : AppColors.darkGrey;

    return Container(
      height: 110.h,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: borderColor,
          width: 4.w,
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
                    Text(
                      controller.currentTime.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 40.sp,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                )),
          ),
          Obx(() => Text(
                '${controller.currentDay.value}, ${controller.currentDate.value}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15.sp,
                  color: secondaryTextColor,
                ),
              )),
        ],
      ),
    );
  }
}
