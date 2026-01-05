import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'SplashController.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Center(
        child: SvgPicture.asset(
          'assets/icons/logo.svg',
          width: 100.w,
          height: 100.w,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            colorScheme.onBackground, // 🔑 otomatis hitam / putih
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
