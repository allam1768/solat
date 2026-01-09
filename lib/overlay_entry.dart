import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_storage/get_storage.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(412, 917),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: OverlayScreen(),
        );
      },
    );
  }
}

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? data;
  Timer? autoSnoozeTimer;
  Timer? countdownTimer;
  int remainingSeconds = 0;
  bool isProcessing = false;

  late AnimationController _pulseController;
  late AnimationController _shakeController;

  final _storage = GetStorage();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    FlutterOverlayWindow.overlayListener.listen((event) {
      setState(() {
        data = event;
      });
      _handleNewData(event);
    });
  }

  void _handleNewData(Map<String, dynamic> event) {
    final intensity = event['intensity'] ?? 'gentle';
    final timeoutSeconds = event['timeoutSeconds'] ?? 0;

    if (intensity == 'high' || intensity == 'critical') {
      _vibrateByIntensity(intensity);
    }

    if (timeoutSeconds > 0) {
      _startAutoSnoozeTimer(timeoutSeconds);
    }

    if (intensity == 'critical') {
      _shakeController.repeat(reverse: true);
    }
  }

  Future<void> _vibrateByIntensity(String intensity) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      await Vibration.cancel();

      switch (intensity) {
        case 'high':
          await Vibration.vibrate(pattern: [0, 500, 200, 500]);
          break;
        case 'critical':
          await Vibration.vibrate(
            pattern: [0, 1000, 500, 1000, 500],
            repeat: 0,
          );
          break;
      }
    } catch (e) {
      debugPrint('❌ Error vibrating: $e');
    }
  }

  void _startAutoSnoozeTimer(int seconds) {
    autoSnoozeTimer?.cancel();
    countdownTimer?.cancel();

    remainingSeconds = seconds;

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          remainingSeconds--;
        });
      }

      if (remainingSeconds <= 0) {
        timer.cancel();
      }
    });

    autoSnoozeTimer = Timer(Duration(seconds: seconds), _handleAutoSnooze);
  }

  Future<void> _handleAutoSnooze() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      debugPrint('⏰ === AUTO-SNOOZE TRIGGERED ===');

      await Vibration.cancel();
      autoSnoozeTimer?.cancel();
      countdownTimer?.cancel();

      debugPrint('🔄 Closing overlay (backup snoozes will handle next trigger)');

      await Future.delayed(const Duration(milliseconds: 300));
      await _forceCloseOverlay();
      debugPrint('✅ === AUTO-SNOOZE COMPLETE ===');

    } catch (e, stack) {
      debugPrint('❌ Error handling auto snooze: $e');
      debugPrint('Stack: $stack');
      await _forceCloseOverlay();
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _handleDone() async {
    if (isProcessing) {
      debugPrint('⚠️ Already processing, ignoring...');
      return;
    }
    setState(() => isProcessing = true);

    try {
      debugPrint('🟢 Done button pressed');
      final prayerName = data?['prayerName'] ?? 'Unknown';

      await Vibration.cancel();
      autoSnoozeTimer?.cancel();
      countdownTimer?.cancel();

      debugPrint('📤 Notifying main app: prayer done');
      try {
        await FlutterOverlayWindow.shareData({
          'action': 'prayer_done',
          'prayerName': prayerName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }).timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => null,
        );
        debugPrint('✅ Main app notified');
      } catch (e) {
        debugPrint('⚠️ Could not notify main app: $e');
      }

      // ✅ Tunggu lebih lama agar main app sempat proses
      debugPrint('⏳ Waiting for main app to process...');
      await Future.delayed(const Duration(milliseconds: 800));
      await _forceCloseOverlay();

    } catch (e, stack) {
      debugPrint('❌ Error handling done: $e');
      debugPrint('Stack: $stack');
      await _forceCloseOverlay();
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _handleSnooze() async {
    if (isProcessing) {
      debugPrint('⚠️ Already processing, ignoring...');
      return;
    }
    setState(() => isProcessing = true);

    try {
      debugPrint('⏰ Snooze button pressed');

      await Vibration.cancel();
      autoSnoozeTimer?.cancel();
      countdownTimer?.cancel();

      debugPrint('🔄 Closing overlay (backup snoozes will handle next trigger)');

      await Future.delayed(const Duration(milliseconds: 300));
      await _forceCloseOverlay();

    } catch (e, stack) {
      debugPrint('❌ Error handling snooze: $e');
      debugPrint('Stack: $stack');
      await _forceCloseOverlay();
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _forceCloseOverlay() async {
    debugPrint('🔄 Force closing overlay...');

    for (int i = 0; i < 5; i++) {
      try {
        await Future.delayed(Duration(milliseconds: i * 100));
        final closed = await FlutterOverlayWindow.closeOverlay();
        debugPrint('🔄 Close attempt ${i + 1}: $closed');

        if (closed == true) {
          debugPrint('✅ Overlay closed successfully!');
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Close attempt ${i + 1} error: $e');
      }
    }

    debugPrint('⚠️ All close attempts completed');
  }

  String _getSnoozeDurationText() {
    // ✅ Semua snooze 5 menit (3 overlay system)
    return '5 mnt';
  }

  String _getCountdownText() {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    autoSnoozeTimer?.cancel();
    countdownTimer?.cancel();
    Vibration.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = data?['intensity'] ?? 'gentle';
    return intensity == 'critical'
        ? _buildCriticalOverlay()
        : _buildPopupOverlay();
  }

  Widget _buildCriticalOverlay() {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, _) {
          final shake = (_shakeController.value - 0.5) * 20;
          return Transform.translate(
            offset: Offset(shake, 0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red, Colors.black],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.9, end: 1.1)
                            .animate(_pulseController),
                        child: Icon(
                          Icons.warning_rounded,
                          size: 140.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 40.h),
                      Text(
                        "WAKTU SHOLAT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        data?['prayerName'] ?? '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 52.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Harus dikonfirmasi manual",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 50.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isProcessing ? null : _handleDone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 8,
                          ),
                          child: isProcessing
                              ? SizedBox(
                            height: 22.h,
                            width: 22.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          )
                              : Text(
                            "SUDAH SHOLAT",
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopupOverlay() {
    final showCountdown = remainingSeconds > 0;
    final isClosing = remainingSeconds <= 0 && !isProcessing;

    return Material(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 320.w,
            minWidth: 280.w,
          ),
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isClosing)
                Column(
                  children: [
                    SizedBox(
                      height: 40.h,
                      width: 40.w,
                      child: const CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Snoozing...',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                )
              else ...[
                Icon(
                  Icons.nightlight_round,
                  size: 64.sp,
                  color: Colors.indigo.shade900,
                ),
                SizedBox(height: 16.h),
                Text(
                  data?['prayerName'] ?? 'Prayer',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  data?['message'] ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
                if (showCountdown) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16.sp,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Tutup otomatis dalam ${_getCountdownText()}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing ? null : _handleDone,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.black87,
                            width: 2,
                          ),
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: isProcessing
                            ? SizedBox(
                          height: 14.h,
                          width: 14.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing ? null : _handleSnooze,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.black87,
                            width: 2,
                          ),
                          foregroundColor: Colors.black87,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          _getSnoozeDurationText(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}