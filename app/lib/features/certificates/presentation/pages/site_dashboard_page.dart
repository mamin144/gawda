import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/certificate_files.dart';
import '../bloc/certificate_cubit.dart';
import '../certificate_labels.dart';

/// Site-user dashboard: status of the current half-month period. Records are
/// loaded once by the shell ([CertificateCubit.loadSitesAndRecords]).
class SiteDashboardPage extends StatelessWidget {
  const SiteDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.siteHomeTitle)),
      body: BlocBuilder<CertificateCubit, CertificateState>(
        builder: (context, state) => switch (state) {
          CertificateLoading() => const LoadingView(),
          CertificateError(:final failure) => ErrorView(
            message: failureMessage(failure, l10n),
            onRetry: context.read<CertificateCubit>().loadSitesAndRecords,
          ),
          final CertificateLoaded loaded => _content(context, loaded),
        },
      ),
    );
  }

  Widget _content(BuildContext context, CertificateLoaded loaded) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final now = DateTime.now();
    final half = periodHalfOf(now);
    final current = loaded.records
        .where(
          (c) => c.periodYear == now.year && c.periodMonth == now.month && c.periodHalf == half,
        )
        .firstOrNull;
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.certificatePeriod, style: theme.textTheme.titleMedium),
          SizedBox(height: spacing.sm),
          Text(periodLabel(now.year, now.month, half, l10n)),
          SizedBox(height: spacing.md),
          if (current == null)
            Text(l10n.noCertificates)
          else
            Card(
              child: ListTile(
                title: Text(certificateStatusLabel(current.status, l10n)),
                subtitle: Text(current.amount),
              ),
            ),
        ],
      ),
    );
  }
}
