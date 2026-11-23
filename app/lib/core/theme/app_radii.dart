import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Corner radius scale from `docs/DESIGN_SYSTEM.md` §6.
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({required this.sm, required this.md, required this.lg});

  const AppRadii.standard() : this(sm: 8, md: 12, lg: 16);

  final double sm;
  final double md;
  final double lg;

  @override
  AppRadii copyWith({double? sm, double? md, double? lg}) =>
      AppRadii(sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg);

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) {
      return this;
    }
    return AppRadii(
      sm: ui.lerpDouble(sm, other.sm, t)!,
      md: ui.lerpDouble(md, other.md, t)!,
      lg: ui.lerpDouble(lg, other.lg, t)!,
    );
  }
}
