import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../bloc/login_cubit.dart';

/// Arabic RTL login form. All state lives in [LoginCubit]; navigation is
/// driven by the session, never by this page.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: spacing.formMaxWidth),
              child: BlocBuilder<LoginCubit, LoginState>(
                builder: (context, state) {
                  final cubit = context.read<LoginCubit>();
                  final submitting = state.status == LoginStatus.submitting;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.appTitle, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                      SizedBox(height: spacing.xxl),
                      Text(l10n.loginTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                      SizedBox(height: spacing.xl),
                      TextField(
                        onChanged: cubit.emailChanged,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n.emailLabel,
                          errorText: _fieldError(state.emailError, l10n),
                        ),
                      ),
                      SizedBox(height: spacing.lg),
                      TextField(
                        onChanged: cubit.passwordChanged,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => cubit.submitted(),
                        decoration: InputDecoration(
                          labelText: l10n.passwordLabel,
                          errorText: _fieldError(state.passwordError, l10n),
                        ),
                      ),
                      SizedBox(height: spacing.xl),
                      if (state.failure != null) ...[
                        _FailureBanner(message: _failureMessage(state.failure!, l10n)),
                        SizedBox(height: spacing.lg),
                      ],
                      FilledButton(
                        onPressed: submitting ? null : cubit.submitted,
                        child: submitting
                            ? SizedBox(
                                width: spacing.xl,
                                height: spacing.xl,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              )
                            : Text(l10n.loginButton),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _fieldError(LoginFieldError? error, AppLocalizations l10n) => switch (error) {
    null => null,
    LoginFieldError.required => l10n.fieldRequired,
    LoginFieldError.invalidEmail => l10n.invalidEmail,
  };

  String _failureMessage(AppFailure failure, AppLocalizations l10n) => switch (failure) {
    InvalidCredentialsFailure() => l10n.errorInvalidCredentials,
    NetworkFailure() => l10n.errorNetwork,
    AccountInactiveFailure() => l10n.errorAccountInactive,
    // Duplicate/Forbidden/BusinessRule never arise from sign-in; generic server text.
    NoSessionFailure() ||
    ServerFailure() ||
    DuplicateFailure() ||
    ForbiddenFailure() ||
    BusinessRuleFailure() => l10n.errorServer,
    UnexpectedFailure() => l10n.errorUnexpected,
  };
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final radii = theme.extension<AppRadii>()!;
    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(radii.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
