import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../auth/domain/entities/app_user.dart';

part 'managed_user.freezed.dart';

/// A user as seen by an admin on the users screen. [invitePending] is true
/// until the invited user accepts the invite. [siteIds] is empty for admins
/// (they see every site) and may be empty for a site user (Q18).
@freezed
abstract class ManagedUser with _$ManagedUser {
  const factory ManagedUser({
    required String id,
    required String email,
    required String fullName,
    required UserRole role,
    required bool isActive,
    required bool invitePending,
    required List<String> siteIds,
  }) = _ManagedUser;
}
