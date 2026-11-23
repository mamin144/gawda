import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/auth_repository.dart';

/// Thin wrapper over the auth API so the repository is testable and no
/// Supabase type leaks into the domain layer. Throws raw exceptions;
/// the repository maps them to `AppFailure`.
abstract interface class AuthService {
  Stream<AuthEvent> get events;
  bool get hasSession;
  String? get currentUserId;

  Future<void> signInWithPassword({required String email, required String password});
  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._auth);

  final GoTrueClient _auth;

  @override
  Stream<AuthEvent> get events => _auth.onAuthStateChange.map(
    (state) => state.session != null ? AuthEvent.signedIn : AuthEvent.signedOut,
  );

  @override
  bool get hasSession => _auth.currentSession != null;

  @override
  String? get currentUserId => _auth.currentUser?.id;

  @override
  Future<void> signInWithPassword({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
