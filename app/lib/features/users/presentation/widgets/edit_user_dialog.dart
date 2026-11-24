import 'package:flutter/material.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../sites/domain/entities/site.dart';
import '../../domain/entities/managed_user.dart';
import 'site_multi_select.dart';

/// Saves the edited values. Returns `null` when the save succeeded, or the
/// failure to surface in the dialog.
typedef EditUserSubmit = Future<AppFailure?> Function({
  required String fullName,
  required UserRole role,
  required bool isActive,
  required List<String> siteIds,
});

/// Opens the edit-user dialog. Resolves to `true` when the save succeeded and
/// `null`/`false` when the admin cancelled or dismissed it.
Future<bool?> showEditUserDialog(
  BuildContext context, {
  required ManagedUser initial,
  required List<Site> activeSites,
  required bool isSelf,
  required EditUserSubmit onSubmit,
}) => showDialog<bool>(
  context: context,
  builder: (_) => EditUserDialog(
    initial: initial,
    activeSites: activeSites,
    isSelf: isSelf,
    onSubmit: onSubmit,
  ),
);

class EditUserDialog extends StatefulWidget {
  const EditUserDialog({
    super.key,
    required this.initial,
    required this.activeSites,
    required this.isSelf,
    required this.onSubmit,
  });

  final ManagedUser initial;
  final List<Site> activeSites;
  final bool isSelf;
  final EditUserSubmit onSubmit;

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late final TextEditingController _name;
  late UserRole _role;
  late bool _isActive;
  late Set<String> _siteIds;

  String? _nameError;
  String? _generalError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.fullName);
    _role = widget.initial.role;
    _isActive = widget.initial.isActive;
    _siteIds = {...widget.initial.siteIds};
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final fullName = _name.text.trim();

    setState(() {
      _nameError = fullName.isEmpty ? l10n.fieldRequired : null;
      _generalError = null;
    });
    if (_nameError != null) {
      return;
    }

    setState(() => _submitting = true);
    final siteIds = _role == UserRole.admin ? const <String>[] : ([..._siteIds]..sort());
    final failure = await widget.onSubmit(
      fullName: fullName,
      role: _role,
      isActive: _isActive,
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
      BusinessRuleFailure(code: 'last_admin') => l10n.lastAdminError,
      BusinessRuleFailure(code: 'cannot_change_self') => l10n.userSelfEditHint,
      _ => failureMessage(failure, l10n),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);
    final locked = widget.isSelf;

    return AlertDialog(
      title: Text(l10n.userEditTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
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
              onChanged: locked
                  ? (_) {}
                  : (value) {
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
                      enabled: !locked && !_submitting,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.userRoleSiteUser),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<UserRole>(
                      value: UserRole.admin,
                      enabled: !locked && !_submitting,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.userRoleAdmin),
                    ),
                  ),
                ],
              ),
            ),
            if (locked) ...[
              SizedBox(height: spacing.xs),
              Text(
                l10n.userSelfEditHint,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
            SizedBox(height: spacing.sm),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.userActiveLabel),
              value: _isActive,
              onChanged: locked ? null : (value) => setState(() => _isActive = value),
            ),
            if (_role == UserRole.siteUser)
              SiteMultiSelect(
                sites: widget.activeSites,
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
