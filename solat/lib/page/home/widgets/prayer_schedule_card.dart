import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:solat/core/app_colors.dart';
import '../home_controller.dart';
import 'prayer_item.dart';
import 'sunrise_item.dart';

class PrayerScheduleCard extends GetView<HomeController> {
  const PrayerScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.black : AppColors.white;
    final borderColor = isDark ? AppColors.white : AppColors.black;
    final titleColor = isDark ? AppColors.white : AppColors.black;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: borderColor,
          width: 4.w,
        ),
        color: cardBg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: EdgeInsets.only(
                top: 22.h,
                left: 28.w,
              ),
              child: Text(
                'jadwal sholat',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24.sp,
                  color: titleColor,
                ),
              )),
          SizedBox(height: 20.h),
          Obx(() => PrayerItem(
                iconPath: 'subuh.svg',
                name: 'Subuh',
                prayerKey: 'Subuh',
                time: controller.fajrTime.value,
              )),
          const SunriseItem(),
          Obx(() => PrayerItem(
                iconPath: 'zuhur.svg',
                name: controller.isFriday.value ? 'Jumatan' : 'Dzuhur',
                prayerKey: 'Dzuhur',
                time: controller.dhuhrTime.value,
              )),
          Obx(() => PrayerItem(
                iconPath: 'ashar.svg',
                name: 'Ashar',
                prayerKey: 'Ashar',
                time: controller.asrTime.value,
              )),
          Obx(() => PrayerItem(
                iconPath: 'magrib.svg',
                name: 'Maghrib',
                prayerKey: 'Maghrib',
                time: controller.maghribTime.value,
              )),
          Obx(() => PrayerItem(
                iconPath: 'isya.svg',
                name: 'Isya',
                prayerKey: 'Isya',
                time: controller.ishaTime.value,
              )),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
