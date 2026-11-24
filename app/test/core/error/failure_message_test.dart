import 'package:flutter_test/flutter_test.dart';
import 'package:gawda_app/core/error/app_failure.dart';
import 'package:gawda_app/core/error/failure_message.dart';
import 'package:gawda_app/l10n/gen/app_localizations.dart';
import 'package:gawda_app/l10n/gen/app_localizations_ar.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsAr();

  test('maps every failure to its localized Arabic message', () {
    expect(failureMessage(const NetworkFailure(), l10n), l10n.errorNetwork);
    expect(failureMessage(const InvalidCredentialsFailure(), l10n), l10n.errorInvalidCredentials);
    expect(failureMessage(const AccountInactiveFailure(), l10n), l10n.errorAccountInactive);
    expect(failureMessage(const NoSessionFailure(), l10n), l10n.errorSessionExpired);
    expect(failureMessage(const ServerFailure(code: 'x'), l10n), l10n.errorServer);
    expect(failureMessage(const DuplicateFailure(), l10n), l10n.errorDuplicate);
    expect(failureMessage(const ForbiddenFailure(), l10n), l10n.errorForbidden);
    expect(failureMessage(const BusinessRuleFailure('code_locked'), l10n), l10n.errorBusinessRule);
    expect(failureMessage(const UnexpectedFailure(cause: 'boom'), l10n), l10n.errorUnexpected);
  });

  test('maps the P4 business rule codes to specific messages', () {
    expect(failureMessage(const BusinessRuleFailure('has_sites'), l10n), l10n.errorHasSites);
    expect(failureMessage(const BusinessRuleFailure('already_deleted'), l10n), l10n.errorAlreadyDeleted);
    expect(failureMessage(const BusinessRuleFailure('invalid_transition'), l10n), l10n.errorInvalidTransition);
    expect(failureMessage(const BusinessRuleFailure('not_found'), l10n), l10n.errorNotFound);
  });

  test('messages are distinct for duplicate, forbidden and business rule', () {
    final messages = {
      failureMessage(const DuplicateFailure(), l10n),
      failureMessage(const ForbiddenFailure(), l10n),
      failureMessage(const BusinessRuleFailure('any'), l10n),
    };
    expect(messages, hasLength(3));
  });
}
