import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/managed_user.dart';

part 'managed_user_row.freezed.dart';
part 'managed_user_row.g.dart';

/// Raw row returned by the `admin_list_users()` RPC (migration
/// 20261124083209): id, email, full_name, role, is_active, invite_pending,
/// site_ids (uuid[], may be null).
@freezed
abstract class ManagedUserRow with _$ManagedUserRow {
  const factory ManagedUserRow({
    required String id,
    required String email,
    @JsonKey(name: 'full_name') required String fullName,
    required String role,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'invite_pending') required bool invitePending,
    @JsonKey(name: 'site_ids') List<String>? siteIds,
  }) = _ManagedUserRow;

  factory ManagedUserRow.fromJson(Map<String, dynamic> json) => _$ManagedUserRowFromJson(json);
}

/// Mapping kept out of the freezed class body (see `ProfileRowMapping`).
extension ManagedUserRowMapping on ManagedUserRow {
  ManagedUser toDomain() => ManagedUser(
    id: id,
    email: email,
    fullName: fullName,
    role: userRoleFromDb(role),
    isActive: isActive,
    invitePending: invitePending,
    siteIds: List.unmodifiable(siteIds ?? const <String>[]),
  );
}

/// `public.user_role` value -> [UserRole]. Fast-fails on unknown roles.
UserRole userRoleFromDb(String value) => switch (value) {
  'admin' => UserRole.admin,
  'site_user' => UserRole.siteUser,
  _ => throw FormatException('unknown role: $value'),
};

/// [UserRole] -> `public.user_role` value (also the Edge Function `role`).
String userRoleToDb(UserRole role) => switch (role) {
  UserRole.admin => 'admin',
  UserRole.siteUser => 'site_user',
};
