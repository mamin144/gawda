import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

/// Authorization role, sourced exclusively from `public.profiles.role`.
enum UserRole { admin, siteUser }

/// The signed-in user as the app understands them. Never built from
/// `user_metadata` (user-editable and unsafe for authorization).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String fullName,
    required UserRole role,
    required bool isActive,
  }) = _AppUser;
}
