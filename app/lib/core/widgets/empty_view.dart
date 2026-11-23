import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Shared empty state with an Arabic message supplied by the caller.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: spacing.xxxl, color: theme.colorScheme.outline),
          SizedBox(height: spacing.lg),
          Text(message, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
