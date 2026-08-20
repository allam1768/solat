import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:solat/core/app_colors.dart';
import '../home_controller.dart';

class NextPrayerCard extends GetView<HomeController> {
  final String? label;
  final String? prayerName;
  final String? prayerTime;

  const NextPrayerCard({
    super.key,
    this.label,
    this.prayerName,
    this.prayerTime,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.white : AppColors.black;
    final textColor = isDark ? AppColors.black : AppColors.white;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label ?? 'selanjutnya',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 8.h),
              Obx(() {
                final name = prayerName ?? controller.nextPrayerName.value;
                return Text(
                  name,
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.0,
                  ),
                );
              }),
            ],
          ),
          Obx(() {
            final time = prayerTime ?? controller.nextPrayerTime.value;
            return Text(
              time,
              style: TextStyle(
                fontSize: 38.sp,
                fontWeight: FontWeight.w900,
                color: textColor,
                height: 1.0,
              ),
            );
          }),
        ],
      ),
    );
  }
}
