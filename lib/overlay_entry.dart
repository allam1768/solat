import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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

  late GetStorage _storage;

  @override
  void initState() {
    super.initState();

    _initStorage();

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

  Future<void> _initStorage() async {
    try {
      await GetStorage.init();
      _storage = GetStorage();
    } catch (e) {
      debugPrint('Storage init error: $e');
      _storage = GetStorage();
    }
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
      debugPrint('Vibration error: $e');
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
      await Vibration.cancel();
      autoSnoozeTimer?.cancel();
      countdownTimer?.cancel();

      await Future.delayed(const Duration(milliseconds: 300));
      await _forceCloseOverlay();
    } catch (e) {
      debugPrint('Auto snooze error: $e');
      await _forceCloseOverlay();
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _handleDone() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      final prayerName = data?['prayerName'] ?? 'Unknown';

      await Vibration.cancel();
      autoSnoozeTimer?.cancel();
      countdownTimer?.cancel();

      // Send done signal via notification
      bool signalSent = false;
      try {
        await _sendDoneSignal(prayerName);
        signalSent = true;
      } catch (e) {
        debugPrint('Done signal failed: $e');
      }

      // Try direct communication
      try {
        await FlutterOverlayWindow.shareData({
          'action': 'prayer_done',
          'prayerName': prayerName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }).timeout(
          const Duration(milliseconds: 500),
          onTimeout: () => null,
        );
      } catch (e) {
        debugPrint('Direct communication failed: $e');
      }

      // Fallback - handle locally
      if (!signalSent) {
        await _handleDoneLocally(prayerName);
      }

      await Future.delayed(const Duration(milliseconds: 800));
      await _forceCloseOverlay();
    } catch (e) {
      debugPrint('Handle done error: $e');
      await _forceCloseOverlay();
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _sendDoneSignal(String prayerName) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 998,
        channelKey: 'prayer_overlay_channel',
        title: 'prayer_done_signal',
        body: prayerName,
        displayOnForeground: false,
        displayOnBackground: false,
        showWhen: false,
        autoDismissible: true,
        payload: {
          'type': 'prayer_done',
          'prayerName': prayerName,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      ),
    );
  }

  Future<void> _handleDoneLocally(String prayerName) async {
    try {
      await _storage.write('overlay_attempt_$prayerName', 0);
      await _cancelBackupSnoozesLocally(prayerName);
    } catch (e) {
      debugPrint('Local done handler error: $e');
    }
  }

  Future<void> _cancelBackupSnoozesLocally(String prayerName) async {
    try {
      final snoozeIds = _storage.read('backup_snooze_ids_$prayerName') as List<dynamic>?;

      if (snoozeIds == null || snoozeIds.isEmpty) return;

      for (final id in snoozeIds) {
        try {
          await AwesomeNotifications().cancel(id as int);
        } catch (e) {
          debugPrint('Cancel snooze $id failed: $e');
        }
      }

      await _storage.remove('backup_snooze_ids_$prayerName');
    } catch (e) {
      debugPrint('Cancel backup snoozes error: $e');
    }
  }

  Future<void> _handleSnooze() async {
    if (isProcessing) return;
    setState(() => isProcessing = true);

    try {
      await Vibration.cancel();
      autoSnoozeTimer?.cancel();
      countdownTimer?.cancel();

      await Future.delayed(const Duration(milliseconds: 300));
      await _forceCloseOverlay();
    } catch (e) {
      debugPrint('Handle snooze error: $e');
      await _forceCloseOverlay();
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _forceCloseOverlay() async {
    autoSnoozeTimer?.cancel();
    countdownTimer?.cancel();

    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Vibration cancel error: $e');
    }

    for (int i = 0; i < 5; i++) {
      try {
        await Future.delayed(Duration(milliseconds: i * 100));
        final closed = await FlutterOverlayWindow.closeOverlay();

        if (closed == true) return;
      } catch (e) {
        debugPrint('Close attempt ${i + 1} error: $e');
      }
    }
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
    final prayerName = data?['prayerName'] ?? 'Prayer';
    final message = data?['message'] ?? 'Please pray now.';

    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 340.w,
            minWidth: 300.w,
          ),
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Colors.black,
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/logo.svg',
                width: 80.w,
                height: 80.w,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                prayerName,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 40.h),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _handleDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: isProcessing
                          ? SizedBox(
                        height: 16.h,
                        width: 16.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                          : Text(
                        "I've prayed",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _handleSnooze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "On my way",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextButton(
                    onPressed: isProcessing ? null : _forceCloseOverlay,
                    child: Text(
                      'Skip this time',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.black12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupOverlay() {
    final prayerName = data?['prayerName'] ?? 'Prayer';
    final message = data?['message'] ?? 'Please pray soon.';

    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 340.w,
            minWidth: 300.w,
          ),
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: Colors.black,
              width: 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 40,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/logo.svg',
                width: 80.w,
                height: 80.w,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                prayerName,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 40.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _handleDone,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: isProcessing
                          ? SizedBox(
                        height: 16.h,
                        width: 16.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                          : Text(
                        "I've prayed",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : _handleSnooze,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.r),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Later",
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
          ),
        ),
      ),
    );
  }
}