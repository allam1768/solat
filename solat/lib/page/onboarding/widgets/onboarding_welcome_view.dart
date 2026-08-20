import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import '../onboarding_controller.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingWelcomeView extends GetView<OnboardingController> {
  const OnboardingWelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Center(
            child: SvgPicture.asset(
              'assets/icons/logo.svg',
              width: 140.w,
              height: 140.w,
            ),
          ),
          Text(
            'assalamualaikum!',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            'jaga sholatmu, Allah jaga hidupmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
            ),
          ),
          const Spacer(),
          AppButton.filled(
            text: 'yuk, mulai !',
            onTap: () => controller.nextPage(),
          ),
        ],
      ),
    );
  }
}
