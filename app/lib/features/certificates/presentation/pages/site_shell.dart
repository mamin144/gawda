import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../sites/domain/repositories/sites_repository.dart';
import '../../domain/repositories/certificates_repository.dart';
import '../bloc/certificate_cubit.dart';
import 'certificate_entry_page.dart';
import 'site_dashboard_page.dart';
import 'site_records_page.dart';

/// Site-user shell: bottom navigation over Dashboard / Entry / Records /
/// Account. Owns the [CertificateCubit] shared by all tabs.
class SiteShell extends StatelessWidget {
  const SiteShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CertificateCubit(
        context.read<CertificatesRepository>(),
        context.read<SitesRepository>(),
      )..loadSitesAndRecords(),
      child: const _ShellView(),
    );
  }
}

class _ShellView extends StatefulWidget {
  const _ShellView();

  @override
  State<_ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<_ShellView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          SiteDashboardPage(),
          _EntryTab(),
          SiteRecordsPage(),
          _AccountTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            label: l10n.siteTabDashboard,
          ),
          NavigationDestination(icon: const Icon(Icons.edit_note), label: l10n.siteTabEntry),
          NavigationDestination(icon: const Icon(Icons.list_alt), label: l10n.siteTabRecords),
          NavigationDestination(icon: const Icon(Icons.person_outline), label: l10n.siteTabAccount),
        ],
      ),
    );
  }
}

class _EntryTab extends StatelessWidget {
  const _EntryTab();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).siteTabEntry)),
    body: const CertificateEntryBody(),
  );
}

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<SessionCubit>().state;
    final user = state is SessionAuthenticated ? state.user : null;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteTabAccount)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user == null ? '' : l10n.welcomeUser(user.fullName)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<SessionCubit>().signOut(),
              child: Text(l10n.logoutButton),
            ),
          ],
        ),
      ),
    );
  }
}
