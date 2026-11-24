import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Placeholder body for `/admin/sites` inside the admin shell. The real
/// management screen replaces it in the next P3 task.
class SitesPage extends StatelessWidget {
  const SitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).navSites,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
