import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../settings_controller.dart';

class SettingsLanguageCard extends StatelessWidget {
  final SettingsController controller;
  final bool isDark;

  const SettingsLanguageCard({
    super.key,
    required this.controller,
    required this.isDark,
  });

  void _showLanguagePicker(BuildContext context) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.black : Colors.white;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border(
              top: BorderSide(color: fgColor.withValues(alpha: 0.1), width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: fgColor,
              ),
            ),
            SizedBox(height: 20.h),
            _buildLanguageItem('English', 'en', 'US'),
            _buildLanguageItem('Bahasa Indonesia', 'id', 'ID'),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageItem(String name, String code, String country) {
    final fgColor = isDark ? Colors.white : Colors.black;

    return Obx(() {
      final isSelected = controller.languageCode.value == code;
      return ListTile(
        onTap: () {
          controller.changeLanguage(code, country);
          Get.back();
        },
        leading: Icon(
          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: isSelected ? fgColor : fgColor.withValues(alpha: 0.3),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: fgColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.black : Colors.white;
    final borderColor = isDark ? Colors.white30 : Colors.black12;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: borderColor,
          width: 1.w,
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
            decoration: BoxDecoration(
              color: fgColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.language_rounded,
              size: 20.sp,
              color: fgColor,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'language'.tr,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Obx(() {
                  String langName = 'English';
                  if (controller.languageCode.value == 'id') {
                    langName = 'Bahasa Indonesia';
                  }
                  return Text(
                    langName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: fgColor.withValues(alpha: 0.6),
                    ),
                  );
                }),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showLanguagePicker(context),
            child: Text(
              'Change',
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
