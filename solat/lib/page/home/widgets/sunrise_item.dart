import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:solat/core/app_colors.dart';
import '../home_controller.dart';

class SunriseItem extends GetView<HomeController> {
  const SunriseItem({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = isDark ? AppColors.white : AppColors.black;

    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34.w,
            height: 34.h,
            child: SvgPicture.asset(
              'assets/icons/terbit.svg',
              colorFilter: ColorFilter.mode(
                itemColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Text(
            'Sunrise',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: itemColor,
            ),
          ),
          const Spacer(),
          Obx(() => Text(
                textAlign: TextAlign.center,
                controller.sunriseTime.value,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: itemColor,
                ),
              )),
        ],
      ),
    );
  }
}
