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
  static Color get onRed => Colors.white;
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
  emeraldDeep: Color(0xFF073822),
  emeraldLight: Color(0xFF137A4D),
  mint: Color(0xFFE8F5EE),
  mintSoft: Color(0xFFF3F9F5),
  gold: Color(0xFFC69224),
  amber: Color(0xFFD97706),
  amberBg: Color(0xFFFEF3C7),
  amberBorder: Color(0xFFFDE68A),
  red: Color(0xFFDC2626),
  redBg: Color(0xFFFEE2E2),
  redBorder: Color(0xFFFECACA),
  ink: Color(0xFF111D16),
  slate: Color(0xFF384E42),
  muted: Color(0xFF52685B),
  line: Color(0xFFD8E4DC),
  bg: Color(0xFFF4F7F5),
  card: Color(0xFFFFFFFF),
);

const _dark = _Palette(
  emerald: Color(0xFF1CB576),
  emeraldDeep: Color(0xFF082618),
  emeraldLight: Color(0xFF2FD991),
  mint: Color(0xFF142B20),
  mintSoft: Color(0xFF102018),
  gold: Color(0xFFE5B558),
  amber: Color(0xFFFBBF24),
  amberBg: Color(0xFF231A0C),
  amberBorder: Color(0xFF4D3815),
  red: Color(0xFFF87171),
  redBg: Color(0xFF261212),
  redBorder: Color(0xFF532424),
  ink: Color(0xFFFFFFFF),
  slate: Color(0xFFB4C8BD),
  muted: Color(0xFF7E9A8B),
  line: Color(0xFF283830),
  bg: Color(0xFF0F1613),
  card: Color(0xFF18221D),
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
    final p = dark ? _dark : _light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: p.emerald,
          brightness: brightness,
          primary: p.emerald,
          secondary: p.gold,
          surface: p.card,
        ).copyWith(
          onPrimary: dark ? p.emeraldDeep : Colors.white,
          onSurface: p.ink,
          onSurfaceVariant: p.slate,
          outline: p.line,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.w800, color: p.ink),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: p.ink,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          color: p.ink,
          height: 1.3,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: p.ink,
          height: 1.3,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: p.ink,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: p.ink,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontWeight: FontWeight.w500,
          color: p.ink,
          height: 1.7,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: p.ink,
          height: 1.65,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          fontWeight: FontWeight.w500,
          color: p.slate,
          height: 1.55,
          fontSize: 12.5,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: p.ink,
          height: 1.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: p.line, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.emerald,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: p.emerald.withValues(alpha: 0.4),
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
          foregroundColor: p.emerald,
          side: BorderSide(color: p.line, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.emerald,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.emerald,
        side: BorderSide(color: p.line),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          color: p.slate,
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
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : (dark ? const Color(0xFFC5D6CC) : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.emerald
              : (dark ? const Color(0xFF24342B) : const Color(0xFFE2EBE5)),
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : p.line,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1.0),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: p.card,
        indicatorColor: p.mint,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? p.emerald : p.slate,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? p.ink : p.slate,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.emerald,
        linearTrackColor: p.line,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.card,
        selectedItemColor: p.emerald,
        unselectedItemColor: p.slate,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.emeraldDeep,
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
