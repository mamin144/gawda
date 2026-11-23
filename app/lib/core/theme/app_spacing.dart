import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Spacing scale from `docs/DESIGN_SYSTEM.md` §6. No hardcoded padding in widgets.
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.formMaxWidth,
  });

  const AppSpacing.standard()
    : this(xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, xxxl: 48, formMaxWidth: 640);

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;

  /// Max width for centered forms on large screens (DESIGN_SYSTEM §6).
  final double formMaxWidth;

  @override
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? xxxl,
    double? formMaxWidth,
  }) => AppSpacing(
    xs: xs ?? this.xs,
    sm: sm ?? this.sm,
    md: md ?? this.md,
    lg: lg ?? this.lg,
    xl: xl ?? this.xl,
    xxl: xxl ?? this.xxl,
    xxxl: xxxl ?? this.xxxl,
    formMaxWidth: formMaxWidth ?? this.formMaxWidth,
  );

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) {
      return this;
    }
    return AppSpacing(
      xs: ui.lerpDouble(xs, other.xs, t)!,
      sm: ui.lerpDouble(sm, other.sm, t)!,
      md: ui.lerpDouble(md, other.md, t)!,
      lg: ui.lerpDouble(lg, other.lg, t)!,
      xl: ui.lerpDouble(xl, other.xl, t)!,
      xxl: ui.lerpDouble(xxl, other.xxl, t)!,
      xxxl: ui.lerpDouble(xxxl, other.xxxl, t)!,
      formMaxWidth: ui.lerpDouble(formMaxWidth, other.formMaxWidth, t)!,
    );
  }
}
