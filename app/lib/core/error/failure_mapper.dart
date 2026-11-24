import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_failure.dart';
import 'network_error_stub.dart' if (dart.library.io) 'network_error_io.dart';

/// Machine codes raised as `P0001` (message == code) by database guards and
/// RPCs that map to [BusinessRuleFailure]. Edge Function error codes are NOT
/// mapped here: a `FunctionException` carries an HTTP status and a JSON body,
/// so each feature repository maps its own function contract (e.g.
/// `UsersRepositoryImpl` for `admin-create-user`) and falls back to
/// [mapExceptionToFailure] for anything it does not recognise.
const businessRuleCodes = {
  'cannot_change_self',
  'last_admin',
  'code_locked',
  'invalid_sites',
  'invalid_target',
  'archive_inconsistent',
};

/// Maps any thrown object to the closed [AppFailure] hierarchy.
AppFailure mapExceptionToFailure(Object error) => switch (error) {
  AuthException(code: 'invalid_credentials') => const InvalidCredentialsFailure(),
  AuthException(:final code, :final message) => ServerFailure(code: code, message: message),
  PostgrestException(code: '23505') => const DuplicateFailure(),
  PostgrestException(code: '42501') ||
  PostgrestException(code: 'P0001', message: 'forbidden') => const ForbiddenFailure(),
  PostgrestException(code: 'P0001', :final message) when businessRuleCodes.contains(message) =>
    BusinessRuleFailure(message),
  PostgrestException(:final code, :final message) => ServerFailure(code: code, message: message),
  FunctionException(status: 403) => const ForbiddenFailure(),
  // No HTTP response reached the client (transport failure, status 0).
  FunctionsFetchException() => const NetworkFailure(),
  TimeoutException() || http.ClientException() => const NetworkFailure(),
  _ when isPlatformNetworkError(error) => const NetworkFailure(),
  _ => UnexpectedFailure(cause: error),
};
