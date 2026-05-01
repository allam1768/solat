import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:solat/page/home/widgets/location_card.dart';
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
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                const LocationCard(),
                SizedBox(height: 10.h),
                const TimeCard(),
                SizedBox(height: 10.h),
                const PrayerScheduleCard(),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
