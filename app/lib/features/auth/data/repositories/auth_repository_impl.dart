import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/profile_row.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._profiles);

  final AuthService _auth;
  final ProfileService _profiles;

  @override
  Stream<AuthEvent> get events => _auth.events;

  @override
  bool get hasSession => _auth.hasSession;

  @override
  Future<Result<AppUser>> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
      return await _loadCurrentUser();
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<AppUser>> restoreSession() async {
    if (!_auth.hasSession) {
      return const Left(NoSessionFailure());
    }
    try {
      return await _loadCurrentUser();
    } on PostgrestException catch (error) {
      // Missing or inaccessible profile row: fail closed, never enter the app.
      await _auth.signOut();
      return Left(mapExceptionToFailure(error));
    } catch (error) {
      // Network and other transient errors keep the persisted session.
      return Left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Right(null);
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }

  Future<Result<AppUser>> _loadCurrentUser() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      return const Left(NoSessionFailure());
    }
    final row = await _profiles.fetchProfile(userId);
    final user = ProfileRow.fromJson(row).toDomain();
    if (!user.isActive) {
      await _auth.signOut();
      return const Left(AccountInactiveFailure());
    }
    return Right(user);
  }
}
