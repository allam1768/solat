import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  // =========================================================
  // ☀️ 1. TEMA TERANG (LIGHT THEME)
  // Background: Putih (#FFFFFF) | Warna Utama: Hitam (#000000)
  // Teks Utama: Hitam (#000000) | Teks Sekunder: #333333
  // =========================================================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta Sans',
    brightness: Brightness.light,

    // ---------------------------------------------------------
    // 🎨 1A. WARNA UTAMA & BACKGROUND APP
    // ---------------------------------------------------------
    primaryColor: AppColors.black,
    scaffoldBackgroundColor: AppColors.white,

    colorScheme: const ColorScheme.light(
      primary: AppColors.black,
      secondary: AppColors.white,
      surface: AppColors.white,
      error: AppColors.error,
      onPrimary: AppColors.white,
      onSecondary: AppColors.black,
      onSurface: AppColors.black,
      onError: AppColors.white,
    ),

    // ---------------------------------------------------------
    // 📱 1B. APP BAR / HEADER ATAS
    // ---------------------------------------------------------
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.black),
      titleTextStyle: TextStyle(
        color: AppColors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // ---------------------------------------------------------
    // 🔤 1C. TEKS & UKURAN FONT (TYPOGRAPHY)
    // ---------------------------------------------------------
    textTheme: const TextTheme(
      // Judul Besar / Headline (#000000)
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),

      // Judul Sub-Halaman / Card Title (#000000)
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimaryLight),

      // Teks Isi Konten (Body Utama #000000 & Sekunder #333333)
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimaryLight),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight), // #333333
    ),

    // ---------------------------------------------------------
    // 🔘 1D. TOMBOL / BUTTON STYLING
    // ---------------------------------------------------------
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.black,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // ---------------------------------------------------------
    // 🔲 1E. BORDER & INPUT FORM (TEXTFIELD)
    // ---------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border), // #E8E8E8
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border), // #E8E8E8
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.black, width: 2), // #000000
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: AppColors.textSecondaryLight, // #333333
        fontSize: 14,
      ),
    ),

    // ---------------------------------------------------------
    // ➖ 1F. GARIS PEMBATAS (DIVIDER)
    // ---------------------------------------------------------
    dividerTheme: const DividerThemeData(
      color: AppColors.divider, // #E8E8E8
      thickness: 1,
    ),
  );

  // =========================================================
  // 🌙 2. TEMA GELAP (DARK THEME)
  // Background: Hitam (#000000) | Warna Utama: Putih (#FFFFFF)
  // Teks Utama: Putih (#FFFFFF) | Teks Sekunder: #CCCCCC
  // =========================================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Plus Jakarta Sans',
    brightness: Brightness.dark,

    // ---------------------------------------------------------
    // 🎨 2A. WARNA UTAMA & BACKGROUND APP
    // ---------------------------------------------------------
    primaryColor: AppColors.white,
    scaffoldBackgroundColor: AppColors.black,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      secondary: AppColors.black,
      surface: AppColors.black,
      error: AppColors.error,
      onPrimary: AppColors.black,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
      onError: AppColors.black,
    ),

    // ---------------------------------------------------------
    // 📱 2B. APP BAR / HEADER ATAS
    // ---------------------------------------------------------
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.black,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // ---------------------------------------------------------
    // 🔤 2C. TEKS & UKURAN FONT (TYPOGRAPHY)
    // ---------------------------------------------------------
    textTheme: const TextTheme(
      // Judul Besar / Headline (#FFFFFF)
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimaryDark),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),

      // Judul Sub-Halaman / Card Title (#FFFFFF)
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),

      // Teks Isi Konten (Body Utama #FFFFFF & Sekunder #CCCCCC)
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimaryDark),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textPrimaryDark),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark), // #CCCCCC
    ),

    // ---------------------------------------------------------
    // 🔘 2D. TOMBOL / BUTTON STYLING
    // ---------------------------------------------------------
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.white,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // ---------------------------------------------------------
    // 🔲 2E. BORDER & INPUT FORM (TEXTFIELD)
    // ---------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.black,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkGrey), // #333333
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkGrey), // #333333
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.white, width: 2), // #FFFFFF
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: AppColors.textSecondaryDark, // #CCCCCC
        fontSize: 14,
      ),
    ),

    // ---------------------------------------------------------
    // ➖ 2F. GARIS PEMBATAS (DIVIDER)
    // ---------------------------------------------------------
    dividerTheme: const DividerThemeData(
      color: AppColors.darkGrey, // #333333
      thickness: 1,
    ),
  );
}

