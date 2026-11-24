import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Placeholder body for `/admin/users` inside the admin shell. The real
/// management screen replaces it in the next P3 task.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).navUsers,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
