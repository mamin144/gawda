import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../sites/domain/entities/site.dart';

/// Compact checkbox list used by both user dialogs to pick the sites a site user
/// is responsible for. An empty [sites] list shows a "no sites" note instead.
class SiteMultiSelect extends StatelessWidget {
  const SiteMultiSelect({
    super.key,
    required this.sites,
    required this.selected,
    required this.onChanged,
  });

  final List<Site> sites;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    if (sites.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: spacing.sm),
        child: Text(
          l10n.userNoSites,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(top: spacing.sm, bottom: spacing.xs),
          child: Text(l10n.userSitesLabel, style: theme.textTheme.labelLarge),
        ),
        for (final site in sites)
          CheckboxListTile(
            value: selected.contains(site.id),
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(site.name),
            subtitle: Text(site.code),
            onChanged: (checked) {
              final next = <String>{...selected};
              if (checked ?? false) {
                next.add(site.id);
              } else {
                next.remove(site.id);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
