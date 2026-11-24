import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../bloc/certificate_cubit.dart';
import '../certificate_labels.dart';

/// Site-user records list over every site. Records are loaded by the shell
/// ([CertificateCubit.loadSitesAndRecords]) and refreshed by pull-to-refresh.
/// Tapping a row opens it in the cubit, then calls [onOpen] (the shell
/// switches to the entry tab).
class SiteRecordsPage extends StatelessWidget {
  const SiteRecordsPage({super.key, this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.certificateRecords)),
      body: BlocBuilder<CertificateCubit, CertificateState>(
        builder: (context, state) => switch (state) {
          CertificateLoading() => const LoadingView(),
          CertificateError(:final failure) => ErrorView(
            message: failureMessage(failure, l10n),
            onRetry: context.read<CertificateCubit>().loadSitesAndRecords,
          ),
          CertificateLoaded(records: []) => EmptyView(
            message: l10n.noCertificates,
            icon: Icons.description_outlined,
          ),
          final CertificateLoaded loaded => _list(context, loaded),
        },
      ),
    );
  }

  Widget _list(BuildContext context, CertificateLoaded loaded) {
    final l10n = AppLocalizations.of(context);
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final cubit = context.read<CertificateCubit>();
    return RefreshIndicator(
      onRefresh: cubit.loadAllRecords,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(spacing.lg),
        itemCount: loaded.records.length,
        separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
        itemBuilder: (context, i) {
          final c = loaded.records[i];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text(periodLabel(c.periodYear, c.periodMonth, c.periodHalf, l10n)),
              subtitle: Text(certificateStatusLabel(c.status, l10n)),
              trailing: Text(c.amount),
              onTap: () {
                unawaited(cubit.openCertificate(c.id));
                onOpen?.call();
              },
            ),
          );
        },
      ),
    );
  }
}
