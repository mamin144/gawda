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

/// Site-user records list. Records are loaded once by the shell
/// ([CertificateCubit.loadSitesAndRecords]); this page never reloads itself.
class SiteRecordsPage extends StatelessWidget {
  const SiteRecordsPage({super.key});

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
    return ListView.separated(
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
          ),
        );
      },
    );
  }
}
