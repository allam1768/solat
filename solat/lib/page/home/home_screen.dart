import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:solat/page/home/widgets/location_card.dart';
import 'package:solat/page/home/widgets/next_prayer_card.dart';
import 'package:solat/page/home/widgets/prayer_schedule_card.dart';
import 'package:solat/page/home/widgets/time_card.dart';
import 'home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(
              left: 20.w,
              right: 20.w,
              bottom: 100.h,
            ),
            child: Column(
              children: [
                const LocationCard(),
                SizedBox(height: 15.h),
                const TimeCard(),
                SizedBox(height: 15.h),
                const NextPrayerCard(),
                SizedBox(height: 15.h),
                const PrayerScheduleCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
