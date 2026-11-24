import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';

/// Overview body of the admin shell (`/admin`). The app bar, side navigation
/// and logout live in `AdminShell`; the dashboard arrives in a later phase.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionCubit>().state;
    final user = state is SessionAuthenticated ? state.user : null;
    if (user == null) {
      return const LoadingView();
    }
    return Center(
      child: Text(l10n.welcomeUser(user.fullName), style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
