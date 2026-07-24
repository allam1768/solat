import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : Colors.black;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    final borderColor = isDark ? Colors.white24 : Colors.black12;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fgColor, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'privacy_policy'.tr,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: fgColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: borderColor, width: 1.w),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: fgColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified_user_rounded, color: fgColor, size: 28.sp),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Privacy Matters',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: fgColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Last updated: July 24, 2026',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: fgColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Section 1: Location Data
              _buildPolicySection(
                icon: Icons.location_on_rounded,
                title: 'Location Data & GPS',
                content:
                    'Solat App collects location data solely to calculate precise daily prayer times and determine the Qibla direction for your current area. All calculations are performed offline directly on your device. Your location data is never uploaded to any remote servers, sold, or shared with third parties.',
                fgColor: fgColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              SizedBox(height: 16.h),

              // Section 2: Permissions
              _buildPolicySection(
                icon: Icons.notifications_active_rounded,
                title: 'Permissions Used',
                content:
                    '• Notification Permission: Used to deliver prayer alerts and Friday reminders.\n'
                    '• Exact Alarm Permission: Ensures prayer reminders trigger precisely at scheduled times.\n'
                    '• Display Over Apps (Overlay): Displays full-screen reminder overlays when prayer time approaches.',
                fgColor: fgColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              SizedBox(height: 16.h),

              // Section 3: Data Security
              _buildPolicySection(
                icon: Icons.security_rounded,
                title: 'Data Storage & Security',
                content:
                    'All user settings and preferences (such as language, theme, and reminder options) are stored locally on your device. We do not operate external user tracking databases or behavioral analytics.',
                fgColor: fgColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              SizedBox(height: 16.h),

              // Section 4: Contact
              _buildPolicySection(
                icon: Icons.mail_outline_rounded,
                title: 'Questions & Feedback',
                content:
                    'If you have any questions about this Privacy Policy or data safety practices, please visit our open-source GitHub repository at github.com/allam1768/solat.',
                fgColor: fgColor,
                cardColor: cardColor,
                borderColor: borderColor,
              ),
              SizedBox(height: 30.h),

              Center(
                child: Text(
                  'Solat App • Safe & Transparent for the Ummah',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: fgColor.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection({
    required IconData icon,
    required String title,
    required String content,
    required Color fgColor,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: fgColor, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.sp,
              color: fgColor.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
