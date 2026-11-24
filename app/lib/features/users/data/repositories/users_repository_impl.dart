import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/users_repository.dart';
import '../models/managed_user_row.dart';
import '../services/users_service.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._service);

  final UsersService _service;

  @override
  Future<Result<List<ManagedUser>>> list() => _guard(() async {
    final rows = await _service.fetchUsers();
    return rows.map((row) => ManagedUserRow.fromJson(row).toDomain()).toList(growable: false);
  });

  /// Calls the `admin-create-user` Edge Function, which answers 201 `{id}`.
  @override
  Future<Result<String>> invite({
    required String email,
    required String fullName,
    required UserRole role,
    required List<String> siteIds,
  }) => _guard(() async {
    final data = await _service.createUser({
      'email': email,
      'full_name': fullName,
      'role': userRoleToDb(role),
      'site_ids': siteIds,
    });
    final id = data['id'];
    if (id is! String) {
      throw FormatException('admin-create-user: missing id in response', data);
    }
    return id;
  }, mapError: _mapCreateUserError);

  /// Only these three columns are sent; DB triggers raise `cannot_change_self`
  /// and `last_admin` as `P0001`.
  @override
  Future<Result<void>> update(
    String id, {
    required String fullName,
    required UserRole role,
    required bool isActive,
  }) => _guard(
    () => _service.updateProfile(id, {
      'full_name': fullName,
      'role': userRoleToDb(role),
      'is_active': isActive,
    }),
  );

  @override
  Future<Result<void>> setSites(String id, List<String> siteIds) => _guard(
    () => _service.rpc('admin_set_user_sites', {'p_user': id, 'p_site_ids': siteIds}),
  );

  /// `admin-create-user` HTTP contract: errors are `{error: <code>}`.
  /// Anything not listed here falls back to the generic mapping.
  static AppFailure _mapCreateUserError(Object error) {
    if (error is FunctionException && error is! FunctionsFetchException) {
      final code = _errorCode(error.details);
      switch ((error.status, code)) {
        case (409, _):
          return const BusinessRuleFailure('user_exists');
        case (400, 'invalid_sites'):
          return const BusinessRuleFailure('invalid_sites');
        case (400, _):
          return const ServerFailure(code: 'invalid_request');
        case (500, 'config_missing' || 'create_failed' || 'internal_error'):
          return ServerFailure(code: code);
      }
    }
    return mapExceptionToFailure(error);
  }

  /// Reads `error` from a decoded JSON body (Map) or a raw JSON string body.
  static String? _errorCode(Object? details) {
    var body = details;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } on FormatException {
        return null;
      }
    }
    if (body is Map && body['error'] is String) return body['error'] as String;
    return null;
  }

  Future<Result<T>> _guard<T>(
    Future<T> Function() body, {
    AppFailure Function(Object error) mapError = mapExceptionToFailure,
  }) async {
    try {
      return Right(await body());
    } catch (error) {
      return Left(mapError(error));
    }
  }
}
