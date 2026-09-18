import 'package:flutter/material.dart';

/// Rabbit — Sovereign Scholar visual language.
/// A calm, confident emerald + gold palette built for long study sessions
/// and Khmer-first typography (font: "Kh Writhand").
class AppColors {
  AppColors._();

  static const emerald = Color(0xFF0D5C3A);
  static const emeraldDeep = Color(0xFF0A3F28);
  static const emeraldLight = Color(0xFF137A4D);
  static const mint = Color(0xFFEAF6EF);
  static const mintSoft = Color(0xFFF4FAF6);
  static const gold = Color(0xFFC9972A);
  static const amber = Color(0xFFF3A51D);
  static const amberBg = Color(0xFFFFF7E7);
  static const red = Color(0xFFC83C3C);
  static const redBg = Color(0xFFFFF1F1);
  static const ink = Color(0xFF16251D);
  static const slate = Color(0xFF5F6E66);
  static const muted = Color(0xFF8A9790);
  static const line = Color(0xFFDCE6E0);
  static const bg = Color(0xFFF5F7F6);
  static const card = Color(0xFFFFFFFF);
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Kh Writhand';

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.emerald,
      brightness: Brightness.light,
      primary: AppColors.emerald,
      secondary: AppColors.gold,
      surface: AppColors.card,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3),
        headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35),
        titleSmall: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.35),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.7, fontSize: 16),
        bodyMedium: TextStyle(fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.65, fontSize: 14),
        bodySmall: TextStyle(fontWeight: FontWeight.w500, color: AppColors.slate, height: 1.55, fontSize: 12.5),
        labelLarge: TextStyle(fontWeight: FontWeight.w700, height: 1.3),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.emerald.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emerald,
          side: const BorderSide(color: AppColors.line, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.emerald,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.emerald,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.slate),
        secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.emerald : const Color(0xFFD7E0DB),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.emerald,
        linearTrackColor: Color(0xFFE7EEEA),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.emerald,
        unselectedItemColor: Color(0xFF87938C),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.emeraldDeep,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
