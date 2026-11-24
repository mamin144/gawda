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

/// A unique constraint was violated (Postgres `23505`), e.g. a duplicate site code.
final class DuplicateFailure extends AppFailure {
  const DuplicateFailure();
}

/// The caller is not allowed to perform the action: Postgres `42501`,
/// a `P0001` raise with message `forbidden`, or an Edge Function HTTP 403.
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure();
}

/// A server-side business rule rejected the action. [code] is the machine code
/// raised by the database or Edge Function (e.g. `last_admin`, `code_locked`).
final class BusinessRuleFailure extends AppFailure {
  const BusinessRuleFailure(this.code);

  final String code;

  @override
  bool operator ==(Object other) => other is BusinessRuleFailure && other.code == code;

  @override
  int get hashCode => Object.hash(BusinessRuleFailure, code);
}

/// Anything unclassified; the original object is kept for diagnostics only.
final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure({required this.cause});

  final Object cause;
}
