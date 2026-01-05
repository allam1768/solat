import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'SettingsController.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 35.h),

              // Notification
              _buildSettingsCard(
                context,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _titleText('Notification', isDark),
                    Obx(() => CustomSwitch(
                      value:
                      controller.notificationEnabled.value,
                      onChanged:
                      controller.toggleNotification,
                      isDark: isDark,
                    )),
                  ],
                ),
              ),

              SizedBox(height: 13.h),

              // Overlay Duration
              _buildSettingsCard(
                context,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    _titleText('Overlay Duration', isDark),
                    Row(
                      children: [
                        _circleButton(
                          context,
                          icon: Icons.remove,
                          onTap:
                          controller.decrementDuration,
                        ),
                        SizedBox(width: 2.w),
                        Obx(() => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,

                              width: 1.5.w,

                            ),
                            borderRadius:
                            BorderRadius.circular(
                                5.r),
                          ),
                          child: Text(
                            '${controller.overlayDuration.value} mnt',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight:
                              FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        )),
                        SizedBox(width: 2.w),
                        _circleButton(
                          context,
                          icon: Icons.add,
                          onTap:
                          controller.incrementDuration,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 13.h),

              // Theme
              _buildSettingsCard(
                context,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    _titleText('Theme', isDark),
                    Obx(() => CustomSwitch(
                      value:
                      controller.isDarkTheme.value,
                      onChanged:
                      controller.toggleTheme,
                      isDark: isDark,
                    )),
                  ],
                ),
              ),

              SizedBox(height: 13.h),

              // Language
              _buildSettingsCard(
                context,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    _titleText('Language', isDark),
                    Obx(() => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,

                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white : Colors.black,

                          width: 1.5.w,

                        ),
                        borderRadius:
                        BorderRadius.circular(
                            5.r),
                      ),
                      child: DropdownButton<String>(
                        value: controller
                            .selectedLanguage.value,
                        underline:
                        const SizedBox(),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDark
                              ? Colors.white
                              : Colors.black,
                          size: 20.sp,
                        ),
                        dropdownColor: isDark
                            ? Colors.black
                            : Colors.white,
                        items: controller.languages
                            .map(
                              (lang) =>
                              DropdownMenuItem(
                                value: lang,
                                child: Text(
                                  lang,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                        )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            controller
                                .changeLanguage(v);
                          }
                        },
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= helpers =================

  Widget _titleText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context,
      {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? Colors.white : Colors.black,
          width: 1.5.w,
        ),
      ),
      child: child,
    );
  }

  Widget _circleButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        width: 22.w,
        height: 22.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 1.5.w,
          ),
        ),
        child: Icon(
          icon,
          size: 12.sp,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

// ================= Custom Switch =================

class CustomSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40.w,
        height: 25.h,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(
            color: isDark ? Colors.white : Colors.black,
            width: 1.5.w,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment:
          value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 15.w,
            height: 15.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(
                color: isDark ? Colors.white : Colors.black,
                width: 1.5.w,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
