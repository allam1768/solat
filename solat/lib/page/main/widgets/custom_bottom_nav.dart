import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../main_controller.dart';

class CustomBottomNav extends StatelessWidget {
  CustomBottomNav({super.key});

  final MainController controller = Get.find<MainController>();
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      bottom: true,
      child: Container(
        margin: EdgeInsets.only(
          left: 135.w,
          right: 135.w,
          bottom: 20.h,
        ),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: colorScheme.surface, // ✅ ikut theme
          borderRadius: BorderRadius.circular(100.r),
          border: Border.all(
            color: colorScheme.onSurface, // ✅ border ikut theme
            width: 4.w,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const itemCount = 3;
            final totalGap = gap.w * (itemCount - 1);
            final itemWidth = (constraints.maxWidth - totalGap) / itemCount;

            return Row(
              children: [
                SizedBox(
                  width: itemWidth,
                  child: const _NavItem(
                    index: 0,
                    svgPath: 'assets/icons/home_icon.svg',
                  ),
                ),
                SizedBox(width: gap.w),
                SizedBox(
                  width: itemWidth,
                  child: const _NavItem(
                    index: 1,
                    svgPath: 'assets/icons/qiblat_icon.svg',
                  ),
                ),
                SizedBox(width: gap.w),
                SizedBox(
                  width: itemWidth,
                  child: const _NavItem(
                    index: 2,
                    svgPath: 'assets/icons/seting_icon.svg',
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
    required this.svgPath,
  });

  final int index;
  final String svgPath;

  @override
  Widget build(BuildContext context) {
    final MainController controller = Get.find();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.changeTab(index);
      },
      child: Obx(() {
        final isActive = controller.currentIndex.value == index;

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.onSurface // ✅ active bg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Center(
              child: SvgPicture.asset(
                svgPath,
                width: 20.sp,
                height: 20.sp,
                colorFilter: ColorFilter.mode(
                  isActive
                      ? colorScheme.surface // ✅ kebalik biar kontras
                      : colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
