import '../../l10n/gen/app_localizations.dart';
import 'app_failure.dart';

/// Generic localized message for [failure], shared by admin screens.
/// Screens that know a more specific meaning (e.g. a duplicate site code)
/// show their own field-level message instead.
String failureMessage(AppFailure failure, AppLocalizations l10n) => switch (failure) {
  InvalidCredentialsFailure() => l10n.errorInvalidCredentials,
  NetworkFailure() => l10n.errorNetwork,
  AccountInactiveFailure() => l10n.errorAccountInactive,
  NoSessionFailure() => l10n.errorSessionExpired,
  ServerFailure() => l10n.errorServer,
  DuplicateFailure() => l10n.errorDuplicate,
  ForbiddenFailure() => l10n.errorForbidden,
  BusinessRuleFailure() => l10n.errorBusinessRule,
  UnexpectedFailure() => l10n.errorUnexpected,
};
