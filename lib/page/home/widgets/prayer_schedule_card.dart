import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/app_colors.dart';
import '../HomeController.dart';
import 'prayer_item.dart';
import 'sunrise_item.dart';

class PrayerScheduleCard extends GetView<HomeController> {
  const PrayerScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Jadwal solat',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 30.h),

          // Fajr
          Obx(() => PrayerItem(
            iconPath: 'subuh.svg',
            name: 'Fajr',
            time: controller.fajrTime.value,
          )),
          SizedBox(height: 12.h),

          // Sunrise
          const SunriseItem(),
          SizedBox(height: 12.h),

          // Dhuhr
          Obx(() => PrayerItem(
            iconPath: 'zuhur.svg',
            name: 'Dhuhr',
            time: controller.dhuhrTime.value,
          )),
          SizedBox(height: 24.h),

          // Asr
          Obx(() => PrayerItem(
            iconPath: 'ashar.svg',
            name: 'Asr',
            time: controller.asrTime.value,
          )),
          SizedBox(height: 24.h),

          // Maghrib
          Obx(() => PrayerItem(
            iconPath: 'magrib.svg',
            name: 'Maghrib',
            time: controller.maghribTime.value,
          )),
          SizedBox(height: 24.h),

          // Isha
          Obx(() => PrayerItem(
            iconPath: 'isya.svg',
            name: 'Isha',
            time: controller.ishaTime.value,
          )),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}