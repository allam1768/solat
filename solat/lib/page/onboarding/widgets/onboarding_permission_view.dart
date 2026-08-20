import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../onboarding_controller.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingPermissionView extends GetView<OnboardingController> {
  final int pageIndex;
  final String? imagePath;
  final double? imageWidth;
  final double? imageHeight;
  final String title;
  final String subtitle;
  final RxBool isGrantedRx;
  final RxBool isLoadingRx;
  final VoidCallback onRequest;
  final String actionLabel;
  final String grantedActionLabel;
  final bool isLastPage;

  const OnboardingPermissionView({
    super.key,
    required this.pageIndex,
    this.imagePath,
    this.imageWidth,
    this.imageHeight,
    required this.title,
    required this.subtitle,
    required this.isGrantedRx,
    required this.isLoadingRx,
    required this.onRequest,
    required this.actionLabel,
    this.grantedActionLabel = 'oke, lanjut !',
    this.isLastPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final onNext = isLastPage ? controller.completeOnboarding : controller.nextPage;

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 90.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            subtitle,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333),
              height: 1.5,
            ),
          ),
          Expanded(
            child: Center(
              child: imagePath != null && imagePath!.isNotEmpty
                  ? Image.asset(
                      imagePath!,
                      width: imageWidth,
                      height: imageHeight,
                      fit: BoxFit.contain,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Obx(() {
            final isGranted = isGrantedRx.value;

            return Column(
              children: [
                Visibility(
                  visible: !isGranted,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: AppButton.filled(
                    text: actionLabel,
                    onTap: isLoadingRx.value ? null : onRequest,
                    isLoading: isLoadingRx.value,
                  ),
                ),
                SizedBox(height: 12.h),
                isGranted
                    ? AppButton.filled(
                        text: grantedActionLabel,
                        onTap: onNext,
                      )
                    : AppButton.outlined(
                        borderWidth: 3.w,
                        text: 'nanti aja',
                        onTap: onNext,
                      ),
              ],
            );
          }),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
