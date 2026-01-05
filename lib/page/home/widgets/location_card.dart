import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/app_colors.dart';
import '../HomeController.dart';

class LocationCard extends GetView<HomeController> {
  const LocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.primary,
          width: 1.5.w,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 26.sp,
            color: AppColors.primary,
          ),
          SizedBox(width: 12.w),

          Expanded(
            child: Obx(() {
              if (controller.isLoadingLocation.value) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              String displayText =
              controller.provinceName.value.isNotEmpty
                  ? '${controller.cityName.value}, ${controller.provinceName.value}'
                  : controller.cityName.value;

              return Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
