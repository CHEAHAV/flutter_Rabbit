import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbit/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final light = a.computeLuminance();
  final dark = b.computeLuminance();
  final brighter = light > dark ? light : dark;
  final darker = light > dark ? dark : light;
  return (brighter + 0.05) / (darker + 0.05);
}

void main() {
  test('text and control labels have readable contrast in both themes', () {
    for (final dark in [false, true]) {
      final theme = dark ? AppTheme.dark() : AppTheme.light();
      expect(
        contrast(theme.colorScheme.onSurface, AppColors.card),
        greaterThan(7),
      );
      expect(
        contrast(theme.colorScheme.onSurfaceVariant, AppColors.card),
        greaterThan(4.5),
      );
      expect(
        contrast(theme.colorScheme.onPrimary, AppColors.emerald),
        greaterThan(4.5),
      );
      expect(contrast(AppColors.muted, AppColors.card), greaterThan(4.5));
    }
  });

  test('animated brightness follows the visible palette', () {
    AppColors.setBlend(0.25);
    expect(AppTheme.animated().brightness, Brightness.light);
    AppColors.setBlend(0.75);
    expect(AppTheme.animated().brightness, Brightness.dark);
    AppColors.setBlend(0);
  });

  test('text is pure black on light and pure white on dark', () {
    AppTheme.dark();
    expect(AppColors.ink, const Color(0xFFFFFFFF));
    expect(AppColors.bg, const Color(0xFF000000));
    expect(contrast(AppColors.ink, AppColors.card), greaterThan(15.0));
    AppTheme.light();
    expect(AppColors.ink, const Color(0xFF000000));
    expect(AppColors.card, const Color(0xFFFFFFFF));
    expect(contrast(AppColors.ink, AppColors.card), greaterThan(15.0));
  });

  test('every text color meets WCAG AA on every surface it sits on', () {
    for (final dark in [false, true]) {
      dark ? AppTheme.dark() : AppTheme.light();
      final surfaces = {
        'card': AppColors.card,
        'bg': AppColors.bg,
        'mint': AppColors.mint,
        'mintSoft': AppColors.mintSoft,
      };
      surfaces.forEach((name, surface) {
        for (final text in {
          'ink': AppColors.ink,
          'slate': AppColors.slate,
          'muted': AppColors.muted,
          'emerald': AppColors.emerald,
          'red': AppColors.red,
          'amber': AppColors.amber,
        }.entries) {
          expect(
            contrast(text.value, surface),
            greaterThanOrEqualTo(4.5),
            reason: '${text.key} on $name (dark=$dark)',
          );
        }
      });
      expect(contrast(AppColors.red, AppColors.redBg), greaterThan(4.5));
      expect(contrast(AppColors.onRed, AppColors.red), greaterThan(4.5));
      expect(contrast(AppColors.onEmerald, AppColors.emerald), greaterThan(4.5));
      expect(contrast(AppColors.ink, AppColors.amberBg), greaterThan(7));
    }
    AppTheme.light();
  });
}
