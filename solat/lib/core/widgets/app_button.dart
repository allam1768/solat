import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app_colors.dart';

enum AppButtonVariant { filled, outlined }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double borderWidth;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? height;
  final double? width;
  final bool isLoading;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const AppButton({
    super.key,
    required this.text,
    required this.onTap,
    this.variant = AppButtonVariant.filled,
    this.fontSize,
    this.fontWeight = FontWeight.w800,
    this.borderWidth = 1.5,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.height,
    this.width = double.infinity,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
  });
  factory AppButton.filled({
    required String text,
    required VoidCallback? onTap,
    double? fontSize,
    FontWeight? fontWeight,
    Color? textColor,
    Color? backgroundColor,
    double? borderRadius,
    double? height,
    double? width,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    return AppButton(
      text: text,
      onTap: onTap,
      variant: AppButtonVariant.filled,
      fontSize: fontSize,
      fontWeight: fontWeight,
      textColor: textColor,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      height: height,
      width: width,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  // Factory Constructor untuk Outlined / Stroke Button
  factory AppButton.outlined({
    required String text,
    required VoidCallback? onTap,
    double? fontSize,
    FontWeight? fontWeight,
    double? borderWidth,
    Color? textColor,
    Color? borderColor,
    Color? backgroundColor,
    double? borderRadius,
    double? height,
    double? width,
    bool isLoading = false,
    Widget? leadingIcon,
    Widget? trailingIcon,
  }) {
    return AppButton(
      text: text,
      onTap: onTap,
      variant: AppButtonVariant.outlined,
      fontSize: fontSize,
      fontWeight: fontWeight,
      borderWidth: borderWidth ?? 3.w,
      textColor: textColor,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      height: height,
      width: width,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Warna bawaan untuk Filled
    final defaultFilledBg =
        backgroundColor ?? (isDark ? AppColors.white : AppColors.black);
    final defaultFilledFg =
        textColor ?? (isDark ? AppColors.black : AppColors.white);

    // Warna bawaan untuk Outlined / Stroke
    final defaultOutlinedBorder =
        borderColor ?? (isDark ? AppColors.white : AppColors.black);
    final defaultOutlinedFg =
        textColor ?? (isDark ? AppColors.white : AppColors.black);
    final defaultOutlinedBg = backgroundColor ?? Colors.transparent;

    final isOutlined = variant == AppButtonVariant.outlined;
    final effectiveBgColor = isOutlined ? defaultOutlinedBg : defaultFilledBg;
    final effectiveFgColor = isOutlined ? defaultOutlinedFg : defaultFilledFg;
    final effectiveBorderColor =
        isOutlined ? defaultOutlinedBorder : Colors.transparent;

    final resolvedRadius = borderRadius ?? 30.r;
    final resolvedHeight = height ?? 55.h;
    final resolvedFontSize = fontSize ?? 20.sp;

    return SizedBox(
      width: width ?? double.infinity,
      height: resolvedHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size(width ?? double.infinity, resolvedHeight),
          backgroundColor: effectiveBgColor,
          foregroundColor: effectiveFgColor,
          disabledBackgroundColor:
              isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          disabledForegroundColor:
              isDark ? Colors.grey.shade600 : Colors.grey.shade500,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(resolvedRadius),
            side: isOutlined
                ? BorderSide(color: effectiveBorderColor, width: borderWidth)
                : BorderSide.none,
          ),
        ),
        onPressed: isLoading ? null : onTap,
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveFgColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    SizedBox(width: 8.w),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: resolvedFontSize,
                      fontWeight: fontWeight,
                      color: effectiveFgColor,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    SizedBox(width: 8.w),
                    trailingIcon!,
                  ],
                ],
              ),
      ),
    );
  }
}
