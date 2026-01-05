import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/app_colors.dart';
import '../MainController.dart';

class CustomBottomNav extends StatelessWidget {
  CustomBottomNav({super.key});

  final MainController controller = Get.find<MainController>();
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Container(
        margin: EdgeInsets.only(
          left: 153.w,
          right: 153.w,
          bottom: 16.h,
        ),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.primary,
            width: 1.5.w,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth =
                (constraints.maxWidth - gap.w) / 2;

            return Row(
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _NavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                  ),
                ),
                SizedBox(width: gap.w),
                SizedBox(
                  width: itemWidth,
                  child: _NavItem(
                    index: 1,
                    icon: Icons.settings_outlined,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.icon,
  });

  final int index;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final MainController controller = Get.find();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.changeTab(index);
      },
      child: Obx(() {
        final isActive =
            controller.currentIndex.value == index;

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5.r),
              border: isActive
                  ? null
                  : Border.all(
                color: AppColors.primary,
                width: 1.5.w,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 24.sp,
                color: isActive
                    ? AppColors.secondary
                    : AppColors.primary,
              ),
            ),
          ),
        );
      }),
    );
  }
}
