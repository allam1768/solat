import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../home_controller.dart';
import 'prayer_item.dart';
import 'sunrise_item.dart';

class PrayerScheduleCard extends GetView<HomeController> {
  const PrayerScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: colorScheme.onSurface,
          width: 1.5.w,
        ),
        color: colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'next_prayer'.tr,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 24.sp,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 30.h),

          Obx(() => PrayerItem(
            iconPath: 'subuh.svg',
            name: 'fajr'.tr,
            prayerKey: 'fajr',
            time: controller.fajrTime.value,
          )),
          SizedBox(height: 12.h),

          const SunriseItem(),
          SizedBox(height: 12.h),

          Obx(() => PrayerItem(
            iconPath: 'zuhur.svg',
            name: controller.isFriday.value ? 'friday_prayer'.tr : 'dhuhr'.tr,
            prayerKey: 'dhuhr',
            time: controller.dhuhrTime.value,
          )),
          SizedBox(height: 24.h),

          Obx(() => PrayerItem(
            iconPath: 'ashar.svg',
            name: 'asr'.tr,
            prayerKey: 'asr',
            time: controller.asrTime.value,
          )),
          SizedBox(height: 24.h),

          Obx(() => PrayerItem(
            iconPath: 'magrib.svg',
            name: 'maghrib'.tr,
            prayerKey: 'maghrib',
            time: controller.maghribTime.value,
          )),
          SizedBox(height: 24.h),

          Obx(() => PrayerItem(
            iconPath: 'isya.svg',
            name: 'isha'.tr,
            prayerKey: 'isha',
            time: controller.ishaTime.value,
          )),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }
}
