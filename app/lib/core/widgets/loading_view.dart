import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Shared loading state. Announces itself to screen readers as a live region.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              SizedBox(height: spacing.lg),
              Text(message!, style: textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}
