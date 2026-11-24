import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../entities/managed_user.dart';

/// Admin management of users. Database guards, RLS and the
/// `admin-create-user` Edge Function enforce authorization and business
/// rules; failures come back as [Result] lefts.
abstract interface class UsersRepository {
  Future<Result<List<ManagedUser>>> list();

  /// Invites a new user by email and returns the new user id.
  Future<Result<String>> invite({
    required String email,
    required String fullName,
    required UserRole role,
    required List<String> siteIds,
  });

  Future<Result<void>> update(
    String id, {
    required String fullName,
    required UserRole role,
    required bool isActive,
  });

  /// Replaces the site user's sites with exactly [siteIds] (empty allowed).
  Future<Result<void>> setSites(String id, List<String> siteIds);
}
