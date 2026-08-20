import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'zikir_controller.dart';

class ZikirScreen extends GetView<ZikirController> {
  const ZikirScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ZikirController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'dzikir setelah sholat',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10.h),
            
            // Tab Selector
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Obx(() => Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(25.r),
                  border: Border.all(color: textColor, width: 2.w),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.activeTabIndex.value = 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: controller.activeTabIndex.value == 0
                                ? textColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Bacaan Dzikir',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: controller.activeTabIndex.value == 0
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.activeTabIndex.value = 1,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: controller.activeTabIndex.value == 1
                                ? textColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Tasbih Digital',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: controller.activeTabIndex.value == 1
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ),

            SizedBox(height: 16.h),

            // Tab Content
            Expanded(
              child: Obx(() {
                if (controller.activeTabIndex.value == 0) {
                  return _buildBacaanList(context, textColor, isDark);
                } else {
                  return _buildTasbihCounter(context, textColor, isDark);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBacaanList(BuildContext context, Color textColor, bool isDark) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      itemCount: controller.badaSholatList.length,
      separatorBuilder: (context, index) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        final item = controller.badaSholatList[index];
        return Container(
          padding: EdgeInsets.all(18.w),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: textColor, width: 2.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.arabic,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.8,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                item.latin,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                item.translation,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white54 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasbihCounter(BuildContext context, Color textColor, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(() {
          final phaseIdx = controller.currentPhase.value;
          return Column(
            children: [
              Text(
                controller.phaseArab[phaseIdx],
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                controller.phaseNames[phaseIdx],
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          );
        }),

        SizedBox(height: 30.h),

        // Counter Circle (Interactive Tap)
        Obx(() => GestureDetector(
          onTap: controller.incrementCounter,
          child: Container(
            width: 220.w,
            height: 220.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[900] : Colors.white,
              border: Border.all(color: textColor, width: 6.w),
              boxShadow: [
                BoxShadow(
                  color: textColor.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${controller.counter.value}',
                  style: TextStyle(
                    fontSize: 72.sp,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  '/ ${controller.target.value}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        )),

        SizedBox(height: 30.h),

        Text(
          'tap lingkaran buat ngitung',
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),

        SizedBox(height: 20.h),

        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor,
            side: BorderSide(color: textColor, width: 2.w),
            shape: const StadiumBorder(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
          ),
          onPressed: controller.resetCounter,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
