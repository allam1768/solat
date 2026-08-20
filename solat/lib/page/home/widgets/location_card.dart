import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:solat/core/app_colors.dart';
import '../home_controller.dart';

class LocationCard extends GetView<HomeController> {
  const LocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final secondaryColor = isDark ? AppColors.lightGrey : AppColors.darkGrey;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: Obx(() {
          final hasData = !controller.isLoadingLocation.value &&
              controller.cityName.value.isNotEmpty &&
              controller.cityName.value != 'loading_location' &&
              controller.locationError.value.isEmpty;

          return InkWell(
            borderRadius: BorderRadius.circular(15.r),
            onTap: hasData
                ? null
                : (controller.isLoadingLocation.value
                    ? null
                    : () => controller.handleLocationTap()),
            child: Padding(
              padding: EdgeInsets.only(top: 15.h),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/icons/lokasi_icon.svg',
                    width: 26.sp,
                    height: 26.sp,
                    colorFilter: ColorFilter.mode(
                      primaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Builder(builder: (context) {
                      if (controller.isLoadingLocation.value) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Shimmer.fromColors(
                              baseColor: isDark
                                  ? AppColors.darkGrey
                                  : AppColors.lightGrey,
                              highlightColor: isDark
                                  ? AppColors.neutral
                                  : AppColors.white,
                              child: Container(
                                height: 14.h,
                                width: 80.w,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Shimmer.fromColors(
                              baseColor: isDark
                                  ? AppColors.darkGrey
                                  : AppColors.lightGrey,
                              highlightColor: isDark
                                  ? AppColors.neutral
                                  : AppColors.white,
                              child: Container(
                                height: 20.h,
                                width: 140.w,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final rawCity = controller.cityName.value;
                      final rawProvince = controller.provinceName.value;

                      final city =
                          (rawCity.isEmpty || rawCity == 'loading_location')
                              ? 'lokasi'
                              : rawCity;

                      final province = rawProvince.isEmpty
                          ? (rawCity.isEmpty ? 'tap buat muat ulang' : '')
                          : rawProvince;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          Text(
                            province.isEmpty
                                ? 'tekan untuk muat ulang'
                                : province,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
