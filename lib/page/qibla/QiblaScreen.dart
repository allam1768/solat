  import 'package:flutter/material.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:get/get.dart';
  import 'QiblaController.dart';

  // Tambahkan property ini di QiblaController:
  // var rotation = 0.0.obs;

  class QiblaScreen extends GetView<QiblaController> {
    const QiblaScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),

                // judul qibla di kiri
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Qibla',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // biar height cuma segini
                      children: [
                        // derajat, nempel ke lingkaran
                        Obx(() => Text(
                          '${controller.rotation.value.toStringAsFixed(0)}°',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        )),

                        SizedBox(height: 8.h), // jarak kecil ke lingkaran

                        // kompas
                        Container(
                          width: 280.w,
                          height: 280.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 3.w,
                            ),
                          ),
                          child: Obx(() => CustomPaint(
                            size: Size(280.w, 280.w),
                            painter: QiblaNeedlePainter(
                              needleColor: isDark ? Colors.white : Colors.black,
                              needleScale: 0.5,
                              showDebugCenter: false,
                              rotationAngle: controller.rotation.value,
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            )

          ),
        ),
      );
    }
  }

  // Custom Painter untuk jarum Qibla
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

      // Save canvas state
      canvas.save();

      // Rotate canvas dari titik tengah
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotationAngle * 3.141592653589793 / 180); // Convert degrees to radians
      canvas.translate(-center.dx, -center.dy);

      // Scale factor untuk menyesuaikan ukuran SVG (27x125) ke canvas
      final scaleX = (size.width / 140) * needleScale;
      final scaleY = (size.height / 140) * needleScale;

      // Titik tengah lingkaran kecil di SVG ada di koordinat (13.4949, 111.215)
      // Kita gunakan ini sebagai pivot point
      final circleCenterX = 13.4949;
      final circleCenterY = 111.215;

      // Offset untuk menempatkan titik tengah lingkaran kecil di tengah canvas
      final offsetX = center.dx - (circleCenterX * scaleX);
      final offsetY = center.dy - (circleCenterY * scaleY);

      // Convert SVG path ke Flutter Path
      final path = Path();

      // Main needle shape
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

      // Inner circle (hole)
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

      // Debug: Titik tengah untuk melihat posisi pivot point
      if (showDebugCenter) {
        final debugPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

        // Gambar titik merah di koordinat yang dianggap sebagai center
        final debugCenterX = offsetX + (circleCenterX * scaleX);
        final debugCenterY = offsetY + (circleCenterY * scaleY);

        canvas.drawCircle(
          Offset(debugCenterX, debugCenterY),
          5,
          debugPaint,
        );
      }

      // Restore canvas state
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