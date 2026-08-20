import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../settings_controller.dart';

class SettingsSmartReminderCards extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;

  const SettingsSmartReminderCards({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProfileCard(
          index: 0,
          title: 'standar',
          subtitle: 'notifikasi standar',
          description:
              'notifikasi adzan saat masuk waktu, +30 menit, dan 30 menit sebelum waktu habis.',
        ),
        SizedBox(height: 12.h),
        _buildProfileCard(
          index: 1,
          title: 'pintar',
          subtitle: 'sistem pintar',
          description:
              'notifikasi adzan, plus pengingat di layar pada 30 menit terakhir.',
          isRecommended: true,
        ),
      ],
    );
  }

  Widget _buildProfileCard({
    required int index,
    required String title,
    required String subtitle,
    required String description,
    bool isRecommended = false,
  }) {
    return Obx(() {
      final isSelected = controller.reminderProfile.value == index;
      final fgColor = isDark ? Colors.white : Colors.black;
      final invertedColor = isDark ? Colors.black : Colors.white;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Material(
          color: isSelected ? fgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
          child: InkWell(
            onTap: () => controller.setReminderProfile(index),
            borderRadius: BorderRadius.circular(30.r),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(
                  color: isSelected ? fgColor : fgColor,
                  width: 4.w,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: isSelected ? invertedColor : fgColor,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isSelected
                                  ? invertedColor.withValues(alpha: 0.7)
                                  : fgColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      if (isRecommended && !isSelected)
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: fgColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'paling pas',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              color: fgColor,
                            ),
                          ),
                        )
                      else if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: invertedColor,
                          size: 24.sp,
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: isSelected
                          ? invertedColor.withValues(alpha: 0.8)
                          : fgColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
