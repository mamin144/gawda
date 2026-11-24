import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../bloc/certificate_cubit.dart';

/// Site-user records list.
class SiteRecordsPage extends StatelessWidget {
  const SiteRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.certificateRecords)),
      body: BlocBuilder<CertificateCubit, CertificateState>(
        builder: (context, state) {
          if (state is CertificateLoading) return const LoadingView();
          if (state is CertificateError) {
            return Center(child: Text(l10n.errorServer));
          }
          final loaded = state as CertificateLoaded;
          if (loaded.records.isEmpty && loaded.sites.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<CertificateCubit>().loadRecords(loaded.sites.first.id);
            });
            return const LoadingView();
          }
          if (loaded.records.isEmpty) {
            return EmptyView(message: l10n.noCertificates, icon: Icons.description_outlined);
          }
          return ListView.separated(
            padding: EdgeInsets.all(Theme.of(context).extension<AppSpacing>()!.lg),
            itemCount: loaded.records.length,
            separatorBuilder: (context, index) => SizedBox(height: Theme.of(context).extension<AppSpacing>()!.sm),
            itemBuilder: (context, i) {
              final c = loaded.records[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text('${c.periodYear}-${c.periodMonth.toString().padLeft(2, '0')} (half ${c.periodHalf})'),
                  subtitle: Text(c.status.name),
                  trailing: Text(c.amount),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
