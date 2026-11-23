import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_failure.dart';
import 'network_error_stub.dart' if (dart.library.io) 'network_error_io.dart';

/// Maps any thrown object to the closed [AppFailure] hierarchy.
AppFailure mapExceptionToFailure(Object error) => switch (error) {
  AuthException(code: 'invalid_credentials') => const InvalidCredentialsFailure(),
  AuthException(:final code, :final message) => ServerFailure(code: code, message: message),
  PostgrestException(:final code, :final message) => ServerFailure(code: code, message: message),
  TimeoutException() || http.ClientException() => const NetworkFailure(),
  _ when isPlatformNetworkError(error) => const NetworkFailure(),
  _ => UnexpectedFailure(cause: error),
};
