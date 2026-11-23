import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';

/// P2 placeholder. The site-user bottom navigation, certificate entry and
/// records screens arrive in P4 — nothing beyond the role home is built here.
class SiteHomePage extends StatelessWidget {
  const SiteHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionCubit>().state;
    final user = state is SessionAuthenticated ? state.user : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.siteHomeTitle),
        actions: [
          IconButton(
            tooltip: l10n.logoutButton,
            onPressed: () => context.read<SessionCubit>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? const LoadingView()
          : Center(child: Text(l10n.welcomeUser(user.fullName), style: Theme.of(context).textTheme.titleLarge)),
    );
  }
}
