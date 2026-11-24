import 'package:flutter/material.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/site.dart';

/// Saves the entered values. Returns `null` when the save succeeded, or the
/// failure to surface in the dialog (field-level when it is specific).
typedef SiteFormSubmit = Future<AppFailure?> Function(String code, String name);

/// Opens the add/edit site dialog. Resolves to `true` when a save succeeded
/// and `false`/`null` when the admin cancelled or dismissed it.
Future<bool?> showSiteFormDialog(
  BuildContext context, {
  Site? initial,
  required SiteFormSubmit onSubmit,
}) => showDialog<bool>(
  context: context,
  builder: (_) => SiteFormDialog(initial: initial, onSubmit: onSubmit),
);

/// Add/edit form for a site. The dialog stays open on failure so the admin can
/// correct the input; duplicate codes and locked codes are reported under the
/// code field, every other failure as a general message.
class SiteFormDialog extends StatefulWidget {
  const SiteFormDialog({super.key, this.initial, required this.onSubmit});

  /// When set the dialog edits this site; otherwise it creates a new one.
  final Site? initial;

  final SiteFormSubmit onSubmit;

  @override
  State<SiteFormDialog> createState() => _SiteFormDialogState();
}

class _SiteFormDialogState extends State<SiteFormDialog> {
  static const int _codeMaxLength = 20;
  static const int _nameMaxLength = 120;

  late final TextEditingController _code;
  late final TextEditingController _name;

  String? _codeError;
  String? _nameError;
  String? _codeServerError;
  String? _generalError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial?.code ?? '');
    _name = TextEditingController(text: widget.initial?.name ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final code = _code.text.trim();
    final name = _name.text.trim();
    setState(() {
      _codeError = code.isEmpty ? l10n.fieldRequired : null;
      _nameError = name.isEmpty ? l10n.fieldRequired : null;
      _generalError = null;
    });
    if (_codeError != null || _nameError != null) {
      return;
    }

    setState(() => _submitting = true);
    final failure = await widget.onSubmit(code, name);
    if (!mounted) {
      return;
    }
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      switch (failure) {
        case DuplicateFailure():
          _codeServerError = l10n.siteCodeDuplicate;
        case BusinessRuleFailure(code: 'code_locked'):
          _codeServerError = l10n.siteCodeLocked;
        default:
          _generalError = failureMessage(failure, l10n);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.initial == null ? l10n.siteAddTitle : l10n.siteEditTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _code,
              enabled: !_submitting,
              maxLength: _codeMaxLength,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.siteCodeLabel,
                errorText: _codeError ?? _codeServerError,
              ),
              onChanged: (_) {
                if (_codeServerError != null) {
                  setState(() => _codeServerError = null);
                }
              },
            ),
            SizedBox(height: spacing.lg),
            TextFormField(
              controller: _name,
              enabled: !_submitting,
              maxLength: _nameMaxLength,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.siteNameLabel,
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
              onFieldSubmitted: (_) => _submitting ? null : _submit(),
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
