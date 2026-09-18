import 'package:flutter/material.dart';

/// Rabbit — Sovereign Scholar visual language.
/// A calm, confident emerald + gold palette built for long study sessions
/// and Khmer-first typography (font: "Kh Writhand").
///
/// Every color below is a *getter*, not a constant: it resolves against
/// whichever point [AppColors.setBlend] last landed on between the light
/// and dark palettes. This lets every screen/widget in the app keep
/// writing plain `AppColors.ink` etc. and automatically follow the user's
/// light/dark preference — including a smooth crossfade while it's
/// mid-transition — without each call site needing to thread a
/// [BuildContext] through. [AppTheme.light]/[AppTheme.dark] settle the
/// palette instantly (used by tests and one-off builds); the running app
/// instead drives [AppColors.setBlend] every frame from a
/// [TweenAnimationBuilder] in `app.dart` so the transition actually fades.
class AppColors {
  AppColors._();

  static double _t = 0.0; // 0 = fully light, 1 = fully dark

  /// Uses the palette currently closest to the animation frame.
  static bool get isDark => _t >= 0.5;

  /// Sets the current crossfade position (0 = light, 1 = dark).
  /// Called once per animation frame while transitioning.
  static void setBlend(double t) {
    _t = t.clamp(0.0, 1.0);
  }

  static _Palette get _current {
    if (_t <= 0) return _light;
    if (_t >= 1) return _dark;
    return _Palette.lerp(_light, _dark, _t);
  }

  static Color get emerald => _current.emerald;
  static Color get emeraldDeep => _current.emeraldDeep;
  static Color get emeraldLight => _current.emeraldLight;
  static Color get mint => _current.mint;
  static Color get mintSoft => _current.mintSoft;
  static Color get gold => _current.gold;
  static Color get amber => _current.amber;
  static Color get amberBg => _current.amberBg;
  static Color get amberBorder => _current.amberBorder;
  static Color get red => _current.red;
  static Color get redBg => _current.redBg;
  static Color get redBorder => _current.redBorder;
  static Color get ink => _current.ink;
  static Color get slate => _current.slate;
  static Color get muted => _current.muted;
  static Color get line => _current.line;
  static Color get bg => _current.bg;
  static Color get card => _current.card;
  static Color get onEmerald => isDark ? _current.emeraldDeep : Colors.white;
  static Color get onRed => isDark ? _current.redBg : Colors.white;
}

class _Palette {
  final Color emerald;
  final Color emeraldDeep;
  final Color emeraldLight;
  final Color mint;
  final Color mintSoft;
  final Color gold;
  final Color amber;
  final Color amberBg;
  final Color amberBorder;
  final Color red;
  final Color redBg;
  final Color redBorder;
  final Color ink;
  final Color slate;
  final Color muted;
  final Color line;
  final Color bg;
  final Color card;

  const _Palette({
    required this.emerald,
    required this.emeraldDeep,
    required this.emeraldLight,
    required this.mint,
    required this.mintSoft,
    required this.gold,
    required this.amber,
    required this.amberBg,
    required this.amberBorder,
    required this.red,
    required this.redBg,
    required this.redBorder,
    required this.ink,
    required this.slate,
    required this.muted,
    required this.line,
    required this.bg,
    required this.card,
  });

  static _Palette lerp(_Palette a, _Palette b, double t) {
    return _Palette(
      emerald: Color.lerp(a.emerald, b.emerald, t)!,
      emeraldDeep: Color.lerp(a.emeraldDeep, b.emeraldDeep, t)!,
      emeraldLight: Color.lerp(a.emeraldLight, b.emeraldLight, t)!,
      mint: Color.lerp(a.mint, b.mint, t)!,
      mintSoft: Color.lerp(a.mintSoft, b.mintSoft, t)!,
      gold: Color.lerp(a.gold, b.gold, t)!,
      amber: Color.lerp(a.amber, b.amber, t)!,
      amberBg: Color.lerp(a.amberBg, b.amberBg, t)!,
      amberBorder: Color.lerp(a.amberBorder, b.amberBorder, t)!,
      red: Color.lerp(a.red, b.red, t)!,
      redBg: Color.lerp(a.redBg, b.redBg, t)!,
      redBorder: Color.lerp(a.redBorder, b.redBorder, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      slate: Color.lerp(a.slate, b.slate, t)!,
      muted: Color.lerp(a.muted, b.muted, t)!,
      line: Color.lerp(a.line, b.line, t)!,
      bg: Color.lerp(a.bg, b.bg, t)!,
      card: Color.lerp(a.card, b.card, t)!,
    );
  }
}

const _light = _Palette(
  emerald: Color(0xFF0D5C3A),
  emeraldDeep: Color(0xFF0A3F28),
  emeraldLight: Color(0xFF137A4D),
  mint: Color(0xFFEAF6EF),
  mintSoft: Color(0xFFF4FAF6),
  gold: Color(0xFFC9972A),
  amber: Color(0xFFF3A51D),
  amberBg: Color(0xFFFFF7E7),
  amberBorder: Color(0xFFF0D18F),
  red: Color(0xFFC83C3C),
  redBg: Color(0xFFFFF1F1),
  redBorder: Color(0xFFF0AFAF),
  ink: Color(0xFF16251D),
  slate: Color(0xFF5F6E66),
  muted: Color(0xFF66766D),
  line: Color(0xFFDCE6E0),
  bg: Color(0xFFF5F7F6),
  card: Color(0xFFFFFFFF),
);

const _dark = _Palette(
  emerald: Color(0xFF1FAF74),
  emeraldDeep: Color(0xFF0A2C1C),
  emeraldLight: Color(0xFF29C98A),
  mint: Color(0xFF15291F),
  mintSoft: Color(0xFF101A15),
  gold: Color(0xFFE8B657),
  amber: Color(0xFFFFC24D),
  amberBg: Color(0xFF2B2110),
  amberBorder: Color(0xFF6B551F),
  red: Color(0xFFFF6B6B),
  redBg: Color(0xFF2E1616),
  redBorder: Color(0xFF7A3B3B),
  ink: Color(0xFFEAF3ED),
  slate: Color(0xFF9FB3A7),
  muted: Color(0xFFA0B3A7),
  line: Color(0xFF263229),
  bg: Color(0xFF0E1512),
  card: Color(0xFF171F1A),
);

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Kh Writhand';

  /// Settles [AppColors] fully on the light palette (no crossfade) and
  /// builds its theme. Deterministic — safe for tests and one-off builds.
  static ThemeData light() {
    AppColors.setBlend(0.0);
    return _themeData(Brightness.light);
  }

  /// Settles [AppColors] fully on the dark palette (no crossfade) and
  /// builds its theme. Deterministic — safe for tests and one-off builds.
  static ThemeData dark() {
    AppColors.setBlend(1.0);
    return _themeData(Brightness.dark);
  }

  /// Builds a theme from [AppColors]' *current* (possibly mid-crossfade)
  /// state, without touching it. The running app calls this every frame
  /// while a [TweenAnimationBuilder] drives [AppColors.setBlend], so the
  /// light/dark switch fades smoothly instead of snapping instantly.
  static ThemeData animated() =>
      _themeData(AppColors.isDark ? Brightness.dark : Brightness.light);

  static ThemeData _themeData(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.emerald,
          brightness: brightness,
          primary: AppColors.emerald,
          secondary: AppColors.gold,
          surface: AppColors.card,
        ).copyWith(
          onPrimary: dark ? AppColors.emeraldDeep : Colors.white,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.slate,
          outline: AppColors.line,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          height: 1.7,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
          height: 1.65,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.slate,
          height: 1.55,
          fontSize: 12.5,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          height: 1.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: AppColors.emerald.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emerald,
          side: BorderSide(color: AppColors.line, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
        side: BorderSide(color: AppColors.line),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          color: AppColors.slate,
        ),
        secondaryLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          color: scheme.onPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(AppColors.card),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.emerald
              : AppColors.line,
        ),
        trackOutlineColor: WidgetStatePropertyAll(AppColors.slate),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.mint,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.emerald
                : AppColors.slate,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.slate,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.emerald,
        linearTrackColor: AppColors.line,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.emerald,
        unselectedItemColor: AppColors.slate,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.emeraldDeep,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
