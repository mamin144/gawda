import 'package:flutter/material.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../sites/domain/entities/site.dart';
import 'site_multi_select.dart';

/// Saves the entered values. Returns `null` when the save succeeded, or the
/// failure to surface in the dialog.
typedef InviteUserSubmit = Future<AppFailure?> Function({
  required String email,
  required String fullName,
  required UserRole role,
  required List<String> siteIds,
});

/// Opens the invite-user dialog. Resolves to `true` when the invite succeeded
/// and `null`/`false` when the admin cancelled or dismissed it.
Future<bool?> showInviteUserDialog(
  BuildContext context, {
  required List<Site> sites,
  required InviteUserSubmit onSubmit,
}) => showDialog<bool>(
  context: context,
  builder: (_) => InviteUserDialog(sites: sites, onSubmit: onSubmit),
);

class InviteUserDialog extends StatefulWidget {
  const InviteUserDialog({super.key, required this.sites, required this.onSubmit});

  final List<Site> sites;
  final InviteUserSubmit onSubmit;

  @override
  State<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends State<InviteUserDialog> {
  final _email = TextEditingController();
  final _fullName = TextEditingController();

  UserRole _role = UserRole.siteUser;
  Set<String> _siteIds = <String>{};

  String? _emailError;
  String? _nameError;
  String? _generalError;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final parts = email.split('@');
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final fullName = _fullName.text.trim();

    setState(() {
      _emailError = email.isEmpty
          ? l10n.fieldRequired
          : (_isValidEmail(email) ? null : l10n.invalidEmail);
      _nameError = fullName.isEmpty ? l10n.fieldRequired : null;
      _generalError = null;
    });
    if (_emailError != null || _nameError != null) {
      return;
    }

    setState(() => _submitting = true);
    final siteIds = _role == UserRole.admin ? const <String>[] : ([..._siteIds]..sort());
    final failure = await widget.onSubmit(
      email: email,
      fullName: fullName,
      role: _role,
      siteIds: siteIds,
    );
    if (!mounted) {
      return;
    }
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _generalError = _messageFor(failure, l10n);
    });
  }

  String _messageFor(AppFailure failure, AppLocalizations l10n) {
    return switch (failure) {
      BusinessRuleFailure(code: 'user_exists') => l10n.userExists,
      BusinessRuleFailure(code: 'invalid_sites') => l10n.inviteInvalidSites,
      ServerFailure(code: 'config_missing') => l10n.inviteNotConfigured,
      _ => failureMessage(failure, l10n),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.userInviteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                errorText: _emailError,
              ),
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() => _emailError = null);
                }
              },
            ),
            SizedBox(height: spacing.lg),
            TextFormField(
              controller: _fullName,
              enabled: !_submitting,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.userFullNameLabel,
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
              onFieldSubmitted: (_) => _submitting ? null : _submit(),
            ),
            SizedBox(height: spacing.lg),
            Text(l10n.userRoleLabel, style: theme.textTheme.labelLarge),
            SizedBox(height: spacing.xs),
            RadioGroup<UserRole>(
              groupValue: _role,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _role = value;
                  if (value == UserRole.admin) {
                    _siteIds.clear();
                  }
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<UserRole>(
                      value: UserRole.siteUser,
                      enabled: !_submitting,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.userRoleSiteUser),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserRole>(
                      value: UserRole.admin,
                      enabled: !_submitting,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.userRoleAdmin),
                    ),
                  ),
                ],
              ),
            ),
            if (_role == UserRole.siteUser)
              SiteMultiSelect(
                sites: widget.sites,
                selected: _siteIds,
                onChanged: (value) => setState(() => _siteIds = value),
              ),
            if (_generalError != null) ...[
              SizedBox(height: spacing.sm),
              Text(
                _generalError!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? SizedBox(
                  width: spacing.xl,
                  height: spacing.xl,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
