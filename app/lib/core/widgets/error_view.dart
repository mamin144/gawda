import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../theme/app_spacing.dart';

/// Shared error state. Retry appears only when a retry action makes sense.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: spacing.xxxl, color: theme.colorScheme.error),
          SizedBox(height: spacing.lg),
          Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            SizedBox(height: spacing.xl),
            FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ],
      ),
    );
  }
}
