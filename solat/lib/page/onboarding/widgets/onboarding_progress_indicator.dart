import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int current;
  final int total;

  const OnboardingProgressIndicator({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(total, (index) {
        final isSelected = index == current - 1;
        final isPassedOrActive = index < current;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: isSelected ? 16.w : 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: isPassedOrActive ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(30.r),
            border: isPassedOrActive
                ? null
                : Border.all(
                    color: Colors.black,
                    width: 2.w,
                  ),
          ),
        );
      }),
    );
  }
}
