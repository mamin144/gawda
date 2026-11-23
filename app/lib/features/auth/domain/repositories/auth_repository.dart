import '../../../../core/error/result.dart';
import '../entities/app_user.dart';

/// Session presence events, independent of any Supabase type.
enum AuthEvent { signedIn, signedOut }

/// Single source of truth for authentication state and the current user.
abstract interface class AuthRepository {
  Stream<AuthEvent> get events;
  bool get hasSession;

  Future<Result<AppUser>> signIn({required String email, required String password});
  Future<Result<AppUser>> restoreSession();
  Future<Result<void>> signOut();
}
