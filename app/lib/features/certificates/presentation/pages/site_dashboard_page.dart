import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/certificate.dart';
import '../bloc/certificate_cubit.dart';

/// Site-user dashboard: status of the current half-month period.
class SiteDashboardPage extends StatelessWidget {
  const SiteDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteHomeTitle)),
      body: BlocBuilder<CertificateCubit, CertificateState>(
        builder: (context, state) {
          if (state is CertificateLoading) return const LoadingView();
          if (state is CertificateError) {
            return Center(child: Text(l10n.errorServer));
          }
          final loaded = state as CertificateLoaded;
          final now = DateTime.now();
          final half = now.day <= 15 ? 1 : 2;
          Certificate? current;
          for (final c in loaded.records) {
            if (c.periodYear == now.year && c.periodMonth == now.month && c.periodHalf == half) {
              current = c;
              break;
            }
          }
          // Ensure records are loaded for the first site.
          if (loaded.records.isEmpty && loaded.sites.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<CertificateCubit>().loadRecords(loaded.sites.first.id);
            });
          }
          return Padding(
            padding: EdgeInsets.all(Theme.of(context).extension<AppSpacing>()!.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.certificatePeriod, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('${now.year}-${now.month.toString().padLeft(2, '0')} (half $half)'),
                const SizedBox(height: 16),
                if (current == null)
                  Text(l10n.noCertificates)
                else
                  Card(
                    child: ListTile(
                      title: Text(current.status.name),
                      subtitle: Text(current.amount),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
