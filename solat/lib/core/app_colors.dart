import 'package:flutter/material.dart';

class AppColors {
  // RAW HEX COLORS
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkGrey = Color(0xFF333333);
  static const Color lightGrey = Color(0xFFCCCCCC);
  static const Color neutral = Color(0xFFE8E8E8);

  // CORE APP COLORS
  static const Color primary = black; // Hitam (#000000)
  static const Color secondary = white; // Putih (#FFFFFF)

  // TEXT COLORS - MODE TERANG (LIGHT)
  static const Color textPrimaryLight = black; // Teks utama mode terang (#000000)
  static const Color textSecondaryLight = darkGrey; // Teks sekunder mode terang (#333333)

  // TEXT COLORS - MODE GELAP (DARK)
  static const Color textPrimaryDark = white; // Teks utama mode gelap (#FFFFFF)
  static const Color textSecondaryDark = lightGrey; // Teks sekunder mode gelap (#CCCCCC)

  // COMPATIBILITY ALIASES
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textWhite = white;
  static const Color textLight = lightGrey;

  // BACKGROUND & NEUTRALS
  static const Color background = white;
  static const Color backgroundDark = black;
  static const Color border = neutral;
  static const Color divider = neutral;
  static const Color surface = white;
  static const Color error = black;
}


