import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/app_user.dart';

part 'profile_row.freezed.dart';
part 'profile_row.g.dart';

/// Raw `public.profiles` row — exactly the columns selected from the database
/// (migration 20261123075750): id, full_name, role, is_active.
@freezed
abstract class ProfileRow with _$ProfileRow {
  const factory ProfileRow({
    required String id,
    @JsonKey(name: 'full_name') required String fullName,
    required String role,
    @JsonKey(name: 'is_active') required bool isActive,
  }) = _ProfileRow;

  factory ProfileRow.fromJson(Map<String, dynamic> json) => _$ProfileRowFromJson(json);
}

/// Mapping kept out of the freezed class body: the generated implementation
/// `implements` the interface and would not inherit a concrete method.
extension ProfileRowMapping on ProfileRow {
  /// Fast-fail on unknown roles instead of silently defaulting.
  AppUser toDomain() => AppUser(
    id: id,
    fullName: fullName,
    role: switch (role) {
      'admin' => UserRole.admin,
      'site_user' => UserRole.siteUser,
      _ => throw FormatException('unknown role: $role'),
    },
    isActive: isActive,
  );
}
