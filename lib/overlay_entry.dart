import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_svg/svg.dart';

/// ENTRY POINT overlay (WAJIB)
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

/// ROOT APP overlay
class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    );
  }
}

/// MAIN OVERLAY SCREEN
class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  Map<String, dynamic>? data;
  Timer? autoCloseTimer;

  @override
  void initState() {
    super.initState();

    /// 🔥 Listen data dari main isolate
    FlutterOverlayWindow.overlayListener.listen((event) {
      setState(() {
        data = event;
      });

      /// Auto close berdasarkan duration (menit)
      _startAutoCloseTimer(event['duration']);
    });
  }

  void _startAutoCloseTimer(dynamic duration) {
    autoCloseTimer?.cancel();

    final int minutes =
    duration is int ? duration : int.tryParse('$duration') ?? 5;

    autoCloseTimer = Timer(
      Duration(minutes: minutes),
          () async {
        await FlutterOverlayWindow.closeOverlay();
      },
    );
  }

  @override
  void dispose() {
    autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery
        .of(context)
        .size;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: Container(
            color: Colors.black.withOpacity(0.9),
            padding: const EdgeInsets.all(24),
            child: SafeArea(
              child: Column(
                children: [

                  /// 🔝 LOGO / ICON (TOP CENTER)
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    'assets/icons/logo.svg',
                    width: 72,
                    height: 72,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),


                  const SizedBox(height: 16),

                  /// Divider tipis
                  Container(
                    width: 80,
                    height: 2,
                    color: Colors.white24,
                  ),

                  const Spacer(),

                  /// 🕌 PRAYER NAME
                  Text(
                    data?['prayerName'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 💬 MESSAGE
                  Text(
                    data?['message'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.4,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// ⏰ NEXT PRAYER
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Next: ${data?['nextPrayerTime'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 16,
                        letterSpacing: 0.8,
                        color: Colors.white54,
                      ),
                    ),
                  ),

                  const Spacer(),

                  /// ❌ CLOSE BUTTON
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await FlutterOverlayWindow.closeOverlay();
                    },
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}