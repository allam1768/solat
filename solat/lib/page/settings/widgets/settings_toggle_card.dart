import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:solat/core/app_colors.dart';

class SettingsToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const SettingsToggleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isDark ? AppColors.lightGrey : AppColors.darkGrey;
    final cardColor = isDark ? AppColors.black : AppColors.secondary;
    final borderColor = isDark ? AppColors.background : AppColors.black;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: borderColor,
          width: 4.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            child: SvgPicture.asset(
              iconPath,
              width: 34.w,
              height: 34.w,
              colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: borderColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
          _CustomPillSwitch(
            value: value,
            onChanged: onChanged,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _CustomPillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _CustomPillSwitch({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final switchBorderColor = isDark ? AppColors.secondary : AppColors.black;
    final activeThumbColor = isDark ? AppColors.secondary : AppColors.black;
    final inactiveThumbColor = isDark ? AppColors.secondary : AppColors.black;
    final borderWidth = 3.5.w;
    final trackWidth = 45.w;
    final trackHeight = 25.h;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: trackWidth,
        height: trackHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(trackHeight),
          border: Border.all(
            color: switchBorderColor,
            width: borderWidth,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final innerSize = constraints.maxHeight;
            return AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? activeThumbColor : inactiveThumbColor,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
