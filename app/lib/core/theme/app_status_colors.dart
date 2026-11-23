import 'package:flutter/material.dart';

/// Business-fixed status colors (`docs/PROJECT_PLAN.md` §11) as accessible
/// container/on-container pairs. Status is never conveyed by color alone.
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.approvedContainer,
    required this.approvedOnContainer,
    required this.needsReviewContainer,
    required this.needsReviewOnContainer,
    required this.lateOrReturnedContainer,
    required this.lateOrReturnedOnContainer,
    required this.archivedContainer,
    required this.archivedOnContainer,
  });

  const AppStatusColors.light()
    : this(
        approvedContainer: const Color(0xFFDCFCE7),
        approvedOnContainer: const Color(0xFF166534),
        needsReviewContainer: const Color(0xFFFEF3C7),
        needsReviewOnContainer: const Color(0xFF92400E),
        lateOrReturnedContainer: const Color(0xFFFEE2E2),
        lateOrReturnedOnContainer: const Color(0xFF991B1B),
        archivedContainer: const Color(0xFFE2E8F0),
        archivedOnContainer: const Color(0xFF334155),
      );

  const AppStatusColors.dark()
    : this(
        approvedContainer: const Color(0xFF052E16),
        approvedOnContainer: const Color(0xFF4ADE80),
        needsReviewContainer: const Color(0xFF451A03),
        needsReviewOnContainer: const Color(0xFFFBBF24),
        lateOrReturnedContainer: const Color(0xFF450A0A),
        lateOrReturnedOnContainer: const Color(0xFFFCA5A5),
        archivedContainer: const Color(0xFF1E293B),
        archivedOnContainer: const Color(0xFF94A3B8),
      );

  final Color approvedContainer;
  final Color approvedOnContainer;
  final Color needsReviewContainer;
  final Color needsReviewOnContainer;
  final Color lateOrReturnedContainer;
  final Color lateOrReturnedOnContainer;
  final Color archivedContainer;
  final Color archivedOnContainer;

  @override
  AppStatusColors copyWith({
    Color? approvedContainer,
    Color? approvedOnContainer,
    Color? needsReviewContainer,
    Color? needsReviewOnContainer,
    Color? lateOrReturnedContainer,
    Color? lateOrReturnedOnContainer,
    Color? archivedContainer,
    Color? archivedOnContainer,
  }) => AppStatusColors(
    approvedContainer: approvedContainer ?? this.approvedContainer,
    approvedOnContainer: approvedOnContainer ?? this.approvedOnContainer,
    needsReviewContainer: needsReviewContainer ?? this.needsReviewContainer,
    needsReviewOnContainer: needsReviewOnContainer ?? this.needsReviewOnContainer,
    lateOrReturnedContainer: lateOrReturnedContainer ?? this.lateOrReturnedContainer,
    lateOrReturnedOnContainer: lateOrReturnedOnContainer ?? this.lateOrReturnedOnContainer,
    archivedContainer: archivedContainer ?? this.archivedContainer,
    archivedOnContainer: archivedOnContainer ?? this.archivedOnContainer,
  );

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) {
      return this;
    }
    return AppStatusColors(
      approvedContainer: Color.lerp(approvedContainer, other.approvedContainer, t)!,
      approvedOnContainer: Color.lerp(approvedOnContainer, other.approvedOnContainer, t)!,
      needsReviewContainer: Color.lerp(needsReviewContainer, other.needsReviewContainer, t)!,
      needsReviewOnContainer: Color.lerp(needsReviewOnContainer, other.needsReviewOnContainer, t)!,
      lateOrReturnedContainer: Color.lerp(
        lateOrReturnedContainer,
        other.lateOrReturnedContainer,
        t,
      )!,
      lateOrReturnedOnContainer: Color.lerp(
        lateOrReturnedOnContainer,
        other.lateOrReturnedOnContainer,
        t,
      )!,
      archivedContainer: Color.lerp(archivedContainer, other.archivedContainer, t)!,
      archivedOnContainer: Color.lerp(archivedOnContainer, other.archivedOnContainer, t)!,
    );
  }
}
