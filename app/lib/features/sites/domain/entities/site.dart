import 'package:freezed_annotation/freezed_annotation.dart';

part 'site.freezed.dart';

/// A construction site. Archived sites have `isActive == false` and a non-null
/// [archivedAt]; the database keeps both fields consistent.
@freezed
abstract class Site with _$Site {
  const factory Site({
    required String id,
    required String code,
    required String name,
    required bool isActive,
    DateTime? archivedAt,
  }) = _Site;
}
