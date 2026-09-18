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

  test('dark mode text colors are crystal clear and high contrast', () {
    AppTheme.dark();
    expect(AppColors.ink, const Color(0xFFFFFFFF));
    expect(AppColors.slate, const Color(0xFFB4C8BD));
    expect(contrast(AppColors.ink, AppColors.card), greaterThan(12.0));
    expect(contrast(AppColors.slate, AppColors.card), greaterThan(8.0));
    AppTheme.light();
    expect(AppColors.ink, const Color(0xFF111D16));
    expect(AppColors.slate, const Color(0xFF384E42));
    expect(contrast(AppColors.ink, AppColors.card), greaterThan(12.0));
    expect(contrast(AppColors.slate, AppColors.card), greaterThan(8.0));
  });
}
