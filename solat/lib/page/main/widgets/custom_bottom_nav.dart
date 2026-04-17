import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../MainController.dart';

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
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: colorScheme.surface, // ✅ ikut theme
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: colorScheme.onSurface, // ✅ border ikut theme
            width: 1.5.w,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const itemCount = 3;
            final totalGap = gap.w * (itemCount - 1);
            final itemWidth =
                (constraints.maxWidth - totalGap) / itemCount;

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
                    icon: Icons.explore_outlined,
                  ),
                ),
                SizedBox(width: gap.w),
                SizedBox(
                  width: itemWidth,
                  child: _NavItem(
                    index: 2,
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
    final colorScheme = Theme.of(context).colorScheme;

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
                  ? colorScheme.onSurface // ✅ active bg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5.r),
              border: isActive
                  ? null
                  : Border.all(
                color: colorScheme.onSurface, // ✅ border ikut theme
                width: 1.5.w,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 24.sp,
                color: isActive
                    ? colorScheme.surface // ✅ kebalik biar kontras
                    : colorScheme.onSurface,
              ),
            ),
          ),
        );
      }),
    );
  }
}
