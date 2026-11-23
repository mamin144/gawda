import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';

/// P2 placeholder. The admin dashboard, side navigation and management
/// screens arrive in P3/P5/P6 — nothing beyond the role home is built here.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionCubit>().state;
    final user = state is SessionAuthenticated ? state.user : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminHomeTitle),
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
