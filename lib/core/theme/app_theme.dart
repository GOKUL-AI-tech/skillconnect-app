import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SkillConnect design tokens — berry / serif theme
class AppColors {
  // Brand (Berry)
  static const brand50  = Color(0xFFFBF0F3);
  static const brand100 = Color(0xFFF7E4E9);
  static const brand200 = Color(0xFFEFC9D3);
  static const brand300 = Color(0xFFDD9CAF);
  static const brand400 = Color(0xFFC15B7A);
  static const brand500 = Color(0xFFA32C52);
  static const brand600 = Color(0xFF8A1338);
  static const brand700 = Color(0xFF74102F);
  static const brand800 = Color(0xFF5E0D26);
  static const brand900 = Color(0xFF3D0819);

  // Accent (Blue)
  static const accent400 = Color(0xFF6B8FE0);
  static const accent500 = Color(0xFF2E56C8);
  static const accent600 = Color(0xFF1F3F9E);

  // Teal — secondary accent for tags/skills
  static const teal400 = Color(0xFF3FA79A);
  static const teal500 = Color(0xFF0E6E64);
  static const teal600 = Color(0xFF0A544C);

  // Purple — tertiary accent for badges/gradients
  static const purple400 = Color(0xFF8073B8);
  static const purple500 = Color(0xFF4A3A82);
  static const purple600 = Color(0xFF382C64);

  // Success
  static const success50  = Color(0xFFF0FDF4);
  static const success400 = Color(0xFF4ADE80);
  static const success500 = Color(0xFF22C55E);
  static const success600 = Color(0xFF16A34A);

  // Warning
  static const warning50  = Color(0xFFFFFBEB);
  static const warning400 = Color(0xFFFBBF24);
  static const warning500 = Color(0xFFF59E0B);
  static const warning600 = Color(0xFFD97706);

  // Danger
  static const danger50  = Color(0xFFFFF1F2);
  static const danger400 = Color(0xFFFB7185);
  static const danger500 = Color(0xFFF43F5E);
  static const danger600 = Color(0xFFE11D48);

  // Surface (Slate)
  static const surface50  = Color(0xFFF8FAFC);
  static const surface100 = Color(0xFFF1F5F9);
  static const surface200 = Color(0xFFE2E8F0);
  static const surface300 = Color(0xFFCBD5E1);
  static const surface400 = Color(0xFF94A3B8);
  static const surface500 = Color(0xFF64748B);
  static const surface600 = Color(0xFF475569);
  static const surface700 = Color(0xFF334155);
  static const surface800 = Color(0xFF1E293B);
  static const surface900 = Color(0xFF0F172A);
  static const surface950 = Color(0xFF020617);

  // Warm neutral background (replaces the old cool-slate app background)
  static const warmBg = Color(0xFFFBF9F6);

  // Rotating accent palette for list cards — keyed off a stable id (not
  // index), so a scan down any list reads as a spread of color.
  static const cardPalette = [brand600, purple500, warning600, accent500, teal500];
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand600,
        brightness: Brightness.light,
        primary: AppColors.brand600,
        secondary: AppColors.accent500,
        surface: Colors.white,
        background: AppColors.warmBg,
        error: AppColors.danger500,
      ),
    );
    final textTheme = GoogleFonts.workSansTextTheme(base.textTheme).copyWith(
      displayLarge:  GoogleFonts.domine(textStyle: base.textTheme.displayLarge,  fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.domine(textStyle: base.textTheme.displayMedium, fontWeight: FontWeight.w700),
      displaySmall:  GoogleFonts.domine(textStyle: base.textTheme.displaySmall,  fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.domine(textStyle: base.textTheme.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium:GoogleFonts.domine(textStyle: base.textTheme.headlineMedium,fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.domine(textStyle: base.textTheme.headlineSmall, fontWeight: FontWeight.w700),
    );
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.warmBg,
      cardTheme: CardThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.brand900.withValues(alpha: 0.05)),
        ),
        color: Colors.white,
        shadowColor: AppColors.brand900.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.warmBg,
        foregroundColor: AppColors.surface900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.domine(
          fontSize: 19, fontWeight: FontWeight.w700,
          color: AppColors.surface900,
        ),
        iconTheme: const IconThemeData(color: AppColors.surface700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand600,
          side: const BorderSide(color: AppColors.brand600, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand600,
          textStyle: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surface200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surface200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger500),
        ),
        hintStyle: GoogleFonts.workSans(color: AppColors.surface400, fontSize: 14),
        labelStyle: GoogleFonts.workSans(color: AppColors.surface600, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface100,
        labelStyle: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w500),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.brand100,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? AppColors.brand700 : AppColors.surface400,
        )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.brand700 : AppColors.surface400,
        )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brand600,
        unselectedItemColor: AppColors.surface400,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surface100, thickness: 1, space: 0,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand500,
        brightness: Brightness.dark,
        primary: AppColors.brand400,
        secondary: AppColors.accent400,
        surface: AppColors.surface800,
        background: AppColors.surface950,
        error: AppColors.danger400,
      ),
    );
    final textTheme = GoogleFonts.workSansTextTheme(base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    )).copyWith(
      displayLarge:  GoogleFonts.domine(textStyle: base.textTheme.displayLarge,  fontWeight: FontWeight.w700, color: Colors.white),
      displayMedium: GoogleFonts.domine(textStyle: base.textTheme.displayMedium, fontWeight: FontWeight.w700, color: Colors.white),
      displaySmall:  GoogleFonts.domine(textStyle: base.textTheme.displaySmall,  fontWeight: FontWeight.w700, color: Colors.white),
      headlineLarge: GoogleFonts.domine(textStyle: base.textTheme.headlineLarge, fontWeight: FontWeight.w700, color: Colors.white),
      headlineMedium:GoogleFonts.domine(textStyle: base.textTheme.headlineMedium,fontWeight: FontWeight.w700, color: Colors.white),
      headlineSmall: GoogleFonts.domine(textStyle: base.textTheme.headlineSmall, fontWeight: FontWeight.w700, color: Colors.white),
    );
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.surface950,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: AppColors.surface800,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface900,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.domine(
          fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: AppColors.surface300),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand400,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          textStyle: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surface700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surface700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand400, width: 2),
        ),
        hintStyle: GoogleFonts.workSans(color: AppColors.surface500, fontSize: 14),
        labelStyle: GoogleFonts.workSans(color: AppColors.surface400, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface900,
        selectedItemColor: AppColors.brand400,
        unselectedItemColor: AppColors.surface500,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surface700, thickness: 1, space: 0,
      ),
    );
  }
}
