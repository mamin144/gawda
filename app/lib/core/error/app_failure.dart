/// Closed hierarchy of user-facing failures. No raw exception crosses layers.
sealed class AppFailure {
  const AppFailure();
}

/// Wrong email/password combination.
final class InvalidCredentialsFailure extends AppFailure {
  const InvalidCredentialsFailure();
}

/// No connectivity or the request timed out.
final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

/// The account exists but is deactivated (`profiles.is_active = false`).
final class AccountInactiveFailure extends AppFailure {
  const AccountInactiveFailure();
}

/// No persisted session exists (cold start before login).
final class NoSessionFailure extends AppFailure {
  const NoSessionFailure();
}

/// Server-side error with an optional machine code and message.
final class ServerFailure extends AppFailure {
  const ServerFailure({this.code, this.message});

  final String? code;
  final String? message;
}

/// Anything unclassified; the original object is kept for diagnostics only.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({required this.cause});

  final Object cause;
}
