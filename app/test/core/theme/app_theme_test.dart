import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/theme/app_radii.dart';
import 'package:gawda_app/core/theme/app_spacing.dart';
import 'package:gawda_app/core/theme/app_status_colors.dart';
import 'package:gawda_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme.light', () {
    final theme = AppTheme.light();

    test('uses Material 3 and the bundled Arabic font', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.textTheme.bodyLarge!.fontFamily, 'IBMPlexSansArabic');
    });

    test('applies the verified light palette exactly', () {
      expect(theme.colorScheme.primary, const Color(0xFF0F172A));
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF));
      expect(theme.colorScheme.secondary, const Color(0xFF1E3A8A));
      expect(theme.colorScheme.surface, const Color(0xFFF8FAFC));
      expect(theme.colorScheme.onSurface, const Color(0xFF020617));
      expect(theme.colorScheme.error, const Color(0xFFDC2626));
    });

    test('registers AppSpacing with the design-system scale', () {
      final spacing = theme.extension<AppSpacing>()!;
      expect(spacing.xs, 4);
      expect(spacing.sm, 8);
      expect(spacing.md, 12);
      expect(spacing.lg, 16);
      expect(spacing.xl, 24);
      expect(spacing.xxl, 32);
      expect(spacing.xxxl, 48);
    });

    test('registers AppRadii with the design-system scale', () {
      final radii = theme.extension<AppRadii>()!;
      expect(radii.sm, 8);
      expect(radii.md, 12);
      expect(radii.lg, 16);
    });

    test('registers light status pairs with accessible values', () {
      final status = theme.extension<AppStatusColors>()!;
      expect(status.approvedContainer, const Color(0xFFDCFCE7));
      expect(status.approvedOnContainer, const Color(0xFF166534));
      expect(status.needsReviewContainer, const Color(0xFFFEF3C7));
      expect(status.needsReviewOnContainer, const Color(0xFF92400E));
      expect(status.lateOrReturnedContainer, const Color(0xFFFEE2E2));
      expect(status.lateOrReturnedOnContainer, const Color(0xFF991B1B));
      expect(status.archivedContainer, const Color(0xFFE2E8F0));
      expect(status.archivedOnContainer, const Color(0xFF334155));
    });

    test('guarantees 48dp minimum button targets', () {
      final style = theme.filledButtonTheme.style!;
      final size = style.minimumSize!.resolve({})!;
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });
  });

  group('AppTheme.dark', () {
    final theme = AppTheme.dark();

    test('applies the dark palette and dark status pairs', () {
      expect(theme.colorScheme.primary, const Color(0xFF93C5FD));
      expect(theme.colorScheme.surface, const Color(0xFF0F172A));
      expect(theme.colorScheme.onSurface, const Color(0xFFF8FAFC));
      final status = theme.extension<AppStatusColors>()!;
      expect(status.approvedContainer, const Color(0xFF052E16));
      expect(status.approvedOnContainer, const Color(0xFF4ADE80));
    });
  });

  test('theme extensions lerp without throwing', () {
    final a = AppSpacing.standard();
    final b = a.copyWith(lg: 32);
    expect(a.lerp(b, 0.5).lg, 24);
    final radii = AppRadii.standard();
    expect(radii.lerp(radii.copyWith(md: 24), 0.5).md, 18);
    final status = AppStatusColors.light();
    expect(status.lerp(AppStatusColors.dark(), 1).approvedContainer, const Color(0xFF052E16));
  });
}
