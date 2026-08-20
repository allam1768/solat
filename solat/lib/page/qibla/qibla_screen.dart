import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:solat/core/app_colors.dart';
import 'package:solat/core/widgets/app_button.dart';
import 'qibla_controller.dart';

class QiblaScreen extends GetView<QiblaController> {
  const QiblaScreen({super.key});

  String _getCardinal(double degree) {
    double norm = (degree % 360 + 360) % 360;
    if (norm >= 337.5 || norm < 22.5) return 'N';
    if (norm >= 22.5 && norm < 67.5) return 'NE';
    if (norm >= 67.5 && norm < 112.5) return 'E';
    if (norm >= 112.5 && norm < 157.5) return 'SE';
    if (norm >= 157.5 && norm < 202.5) return 'S';
    if (norm >= 202.5 && norm < 247.5) return 'SW';
    if (norm >= 247.5 && norm < 292.5) return 'W';
    return 'NW';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            top: 16.h,
            bottom: 80.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),

              // Judul Kiblat
              Text(
                'kiblat',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),

              Expanded(
                child: Obx(() {
                  // State Loading
                  if (controller.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(color: textColor),
                    );
                  }

                  // State Error
                  if (controller.errorMessage.value.isNotEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'lokasi kamu belum aktif',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'nyalain lokasi dulu yuk biar arah kiblat kamu pas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.8),
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: 32.h),
                            AppButton.filled(
                              text: 'coba lagi',
                              onTap: controller.refresh,
                              width: 220.w,
                              height: 50.h,
                              fontSize: 16.sp,
                            ),
                            SizedBox(height: 12.h),
                            AppButton.outlined(
                              text: 'buka pengaturan',
                              onTap: controller.openAppSettings,
                              width: 220.w,
                              height: 50.h,
                              fontSize: 16.sp,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // State Normal (Compass UI)
                  final qiblaDeg = controller.qiblaDirection.value;
                  final currentHeading = controller.phoneHeading.value;
                  final cardinal = _getCardinal(currentHeading);
                  final rotation = controller.rotation.value;
                  final isNearQibla = (rotation <= 3 || rotation >= 357);
                  final accentColor = textColor;

                  return SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Angka derajat HP secara real-time
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 150),
                          style: TextStyle(
                            fontSize: 64.sp,
                            fontWeight:
                                isNearQibla ? FontWeight.w800 : FontWeight.w700,
                            color: accentColor,
                            height: 0,
                          ),
                          child: Text('${currentHeading.round()}°'),
                        ),

                        SizedBox(height: 6.h),

                        // Sub-teks Arah & Status Kiblat Realtime
                        Text(
                          isNearQibla
                              ? 'sip, udah pas'
                              : '$cardinal • kiblat ${qiblaDeg.round()}° (Makkah)',
                          style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: isNearQibla
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isDark
                                  ? (isNearQibla
                                      ? AppColors.secondary
                                      : AppColors.lightGrey)
                                  : (isNearQibla
                                      ? AppColors.black
                                      : AppColors.darkGrey),
                              height: 0),
                        ),

                        SizedBox(height: 38.h),

                        // Lingkaran Kompas
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 280.w,
                          height: 280.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: textColor,
                              width: isNearQibla ? 7.w : 4.w,
                            ),
                          ),
                          child: CustomPaint(
                            size: Size(280.w, 280.w),
                            painter: QiblaNeedlePainter(
                              needleColor: textColor,
                              needleScale: isNearQibla ? 0.55 : 0.5,
                              showDebugCenter: false,
                              rotationAngle: rotation,
                            ),
                          ),
                        ),

                        SizedBox(height: 30.h),

                        // Himbauan Kalibrasi
                        if (controller.needsCalibration.value)
                          InkWell(
                            onTap: () => _showCalibrationDialog(context),
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 12.h),
                              decoration: BoxDecoration(
                                color: textColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: textColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.screen_rotation_rounded,
                                    color: textColor,
                                    size: 28.sp,
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Text(
                                      'putar HP kamu membentuk angka 8 buat kalibrasi kompas.',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: textColor.withValues(alpha: 0.5),
                                    size: 18.sp,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCalibrationDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.screen_rotation_rounded,
                size: 56.sp,
                color: textColor,
              ),
              SizedBox(height: 16.h),
              Text(
                'kalibrasi kompas',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'putar HP kamu membentuk angka 8 buat kalibrasi kompas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: textColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: Text('tutup',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QiblaNeedlePainter extends CustomPainter {
  final Color needleColor;
  final double needleScale;
  final double centerYOffset;
  final bool showDebugCenter;
  final double rotationAngle;

  QiblaNeedlePainter({
    required this.needleColor,
    this.needleScale = 1.0,
    this.centerYOffset = 0,
    this.showDebugCenter = false,
    this.rotationAngle = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2 + centerYOffset);

    canvas.save();

    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle * 3.141592653589793 / 180);
    canvas.translate(-center.dx, -center.dy);

    final scaleX = (size.width / 140) * needleScale;
    final scaleY = (size.height / 140) * needleScale;

    final circleCenterX = 13.4949;
    final circleCenterY = 111.215;

    final offsetX = center.dx - (circleCenterX * scaleX);
    final offsetY = center.dy - (circleCenterY * scaleY);

    final path = Path();

    path.moveTo(offsetX + 12.0037 * scaleX, offsetY + 1.3379 * scaleY);
    path.cubicTo(
      offsetX + 12.1975 * scaleX,
      offsetY + (-0.445952) * scaleY,
      offsetX + 14.7924 * scaleX,
      offsetY + (-0.445978) * scaleY,
      offsetX + 14.9861 * scaleX,
      offsetY + 1.3379 * scaleY,
    );
    path.lineTo(offsetX + 26.9812 * scaleX, offsetY + 112.066 * scaleY);
    path.cubicTo(
      offsetX + 26.9915 * scaleX,
      offsetY + 112.162 * scaleY,
      offsetX + 26.9926 * scaleX,
      offsetY + 112.261 * scaleY,
      offsetX + 26.9842 * scaleX,
      offsetY + 112.356 * scaleY,
    );
    path.cubicTo(
      offsetX + 25.5248 * scaleX,
      offsetY + 128.791 * scaleY,
      offsetX + 1.46504 * scaleX,
      offsetY + 128.791 * scaleY,
      offsetX + 0.00565515 * scaleX,
      offsetY + 112.356 * scaleY,
    );
    path.cubicTo(
      offsetX + (-0.00282629) * scaleX,
      offsetY + 112.261 * scaleY,
      offsetX + (-0.00170159) * scaleX,
      offsetY + 112.162 * scaleY,
      offsetX + 0.00858484 * scaleX,
      offsetY + 112.066 * scaleY,
    );
    path.lineTo(offsetX + 12.0037 * scaleX, offsetY + 1.3379 * scaleY);
    path.close();

    path.moveTo(offsetX + 13.4949 * scaleX, offsetY + 101.215 * scaleY);
    path.cubicTo(
      offsetX + 7.97219 * scaleX,
      offsetY + 101.215 * scaleY,
      offsetX + 3.49512 * scaleX,
      offsetY + 105.692 * scaleY,
      offsetX + 3.49491 * scaleX,
      offsetY + 111.215 * scaleY,
    );
    path.cubicTo(
      offsetX + 3.49491 * scaleX,
      offsetY + 116.738 * scaleY,
      offsetX + 7.97207 * scaleX,
      offsetY + 121.215 * scaleY,
      offsetX + 13.4949 * scaleX,
      offsetY + 121.215 * scaleY,
    );
    path.cubicTo(
      offsetX + 19.0177 * scaleX,
      offsetY + 121.215 * scaleY,
      offsetX + 23.4949 * scaleX,
      offsetY + 116.738 * scaleY,
      offsetX + 23.4949 * scaleX,
      offsetY + 111.215 * scaleY,
    );
    path.cubicTo(
      offsetX + 23.4947 * scaleX,
      offsetY + 105.692 * scaleY,
      offsetX + 19.0175 * scaleX,
      offsetY + 101.215 * scaleY,
      offsetX + 13.4949 * scaleX,
      offsetY + 101.215 * scaleY,
    );
    path.close();

    canvas.drawPath(path, paint);

    if (showDebugCenter) {
      final debugPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final debugCenterX = offsetX + (circleCenterX * scaleX);
      final debugCenterY = offsetY + (circleCenterY * scaleY);

      canvas.drawCircle(
        Offset(debugCenterX, debugCenterY),
        5,
        debugPaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant QiblaNeedlePainter oldDelegate) {
    return oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.needleScale != needleScale ||
        oldDelegate.centerYOffset != centerYOffset ||
        oldDelegate.showDebugCenter != showDebugCenter;
  }
}
