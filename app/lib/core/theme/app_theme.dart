import 'package:flutter/material.dart';

import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_status_colors.dart';

/// Material 3 themes built strictly from `docs/DESIGN_SYSTEM.md` tokens.
abstract final class AppTheme {
  static const String fontFamily = 'IBMPlexSansArabic';
  static const Color _seed = Color(0xFF1E3A8A);

  static ThemeData light() => _build(
    ColorScheme.fromSeed(seedColor: _seed).copyWith(
      primary: const Color(0xFF0F172A),
      onPrimary: const Color(0xFFFFFFFF),
      secondary: const Color(0xFF1E3A8A),
      onSecondary: const Color(0xFFFFFFFF),
      tertiary: const Color(0xFFA16207),
      onTertiary: const Color(0xFFFFFFFF),
      surface: const Color(0xFFF8FAFC),
      onSurface: const Color(0xFF020617),
      surfaceContainer: const Color(0xFFFFFFFF),
      outline: const Color(0xFFE2E8F0),
      error: const Color(0xFFDC2626),
      onError: const Color(0xFFFFFFFF),
    ),
    const AppStatusColors.light(),
  );

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark).copyWith(
      primary: const Color(0xFF93C5FD),
      onPrimary: const Color(0xFF0F172A),
      secondary: const Color(0xFFBFDBFE),
      onSecondary: const Color(0xFF0F172A),
      surface: const Color(0xFF0F172A),
      onSurface: const Color(0xFFF8FAFC),
      surfaceContainer: const Color(0xFF1E293B),
      outline: const Color(0xFF334155),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF0F172A),
    ),
    const AppStatusColors.dark(),
  );

  static ThemeData _build(ColorScheme scheme, AppStatusColors status) {
    const spacing = AppSpacing.standard();
    const radii = AppRadii.standard();
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: fontFamily);
    final textTheme = base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5, letterSpacing: 0),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.5, letterSpacing: 0),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radii.sm));
    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [spacing, radii, status],
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radii.sm)),
        contentPadding: EdgeInsets.symmetric(horizontal: spacing.lg, vertical: spacing.md),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48), shape: buttonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(minimumSize: const Size(48, 48), shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), shape: buttonShape),
      ),
    );
  }
}
