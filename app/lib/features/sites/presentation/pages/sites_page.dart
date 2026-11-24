import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/failure_message.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_status_colors.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/site.dart';
import '../../domain/repositories/sites_repository.dart';
import '../bloc/sites_cubit.dart';
import '../widgets/site_form_dialog.dart';

/// Admin sites management screen. Rendered inside the admin shell, so it owns
/// no Scaffold or AppBar; the add action is a FAB-sized button in the body.
class SitesPage extends StatelessWidget {
  const SitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SitesCubit(context.read<SitesRepository>())..load(),
      child: const _SitesView(),
    );
  }
}

/// Actions offered by a row's overflow menu.
enum _SiteAction { edit, archive, restore }

class _SitesView extends StatelessWidget {
  const _SitesView();

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<SitesCubit, SitesState>(
      builder: (context, state) {
        return Stack(
          children: [
            Positioned.fill(child: _buildBody(context, state)),
            if (state is SitesLoaded)
              PositionedDirectional(
                end: spacing.xl,
                bottom: spacing.xl,
                child: FloatingActionButton(
                  tooltip: l10n.siteAdd,
                  onPressed: () => _openSiteForm(context),
                  child: const Icon(Icons.add),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, SitesState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SitesCubit>();
    return switch (state) {
      SitesLoading() => const LoadingView(),
      SitesError(:final failure) => ErrorView(
        message: failureMessage(failure, l10n),
        onRetry: cubit.load,
      ),
      SitesLoaded() => _LoadedView(state: state),
    };
  }
}

/// Opens the add/edit dialog and performs the matching cubit action.
Future<void> _openSiteForm(BuildContext context, {Site? initial}) async {
  final cubit = context.read<SitesCubit>();
  await showSiteFormDialog(
    context,
    initial: initial,
    onSubmit: (code, name) async {
      final succeeded = initial == null
          ? await cubit.create(code, name)
          : await cubit.update(initial.id, code, name);
      if (succeeded) {
        return null;
      }
      final state = cubit.state;
      return state is SitesLoaded
          ? (state.actionError ?? const ServerFailure())
          : const ServerFailure();
    },
  );
}

/// Runs the row menu action, asking for confirmation before archiving.
Future<void> _handleSiteAction(BuildContext context, Site site, _SiteAction action) async {
  switch (action) {
    case _SiteAction.edit:
      await _openSiteForm(context, initial: site);
    case _SiteAction.archive:
      final confirmed = await _confirmArchive(context, site);
      if (!context.mounted || !confirmed) {
        return;
      }
      await _setSiteArchived(context, site, archived: true);
    case _SiteAction.restore:
      await _setSiteArchived(context, site, archived: false);
  }
}

Future<bool> _confirmArchive(BuildContext context, Site site) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.siteArchiveConfirmTitle),
      content: Text(l10n.siteArchiveConfirmBody(site.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.siteArchive),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Archives or restores [site]; a failure keeps the list and shows a snackbar.
Future<void> _setSiteArchived(BuildContext context, Site site, {required bool archived}) async {
  final cubit = context.read<SitesCubit>();
  final l10n = AppLocalizations.of(context);
  final succeeded = await cubit.setArchived(site.id, archived: archived);
  if (!context.mounted || succeeded) {
    return;
  }
  final state = cubit.state;
  final failure = state is SitesLoaded ? state.actionError : null;
  if (failure == null) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(failureMessage(failure, l10n))),
  );
}

/// Search, filter and list for a loaded sites state.
class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final SitesLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SitesCubit>();
    final visible = state.visibleSites;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: cubit.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.sitesSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          SizedBox(height: spacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SegmentedButton<SitesFilter>(
              segments: [
                ButtonSegment(value: SitesFilter.active, label: Text(l10n.sitesFilterActive)),
                ButtonSegment(value: SitesFilter.archived, label: Text(l10n.sitesFilterArchived)),
                ButtonSegment(value: SitesFilter.all, label: Text(l10n.sitesFilterAll)),
              ],
              selected: {state.filter},
              onSelectionChanged: (selection) => cubit.setFilter(selection.first),
            ),
          ),
          SizedBox(height: spacing.md),
          Expanded(
            child: visible.isEmpty
                ? EmptyView(message: _emptyMessage(l10n), icon: Icons.location_city_outlined)
                : ListView.separated(
                    padding: EdgeInsets.only(top: spacing.xs, bottom: spacing.xxxl + spacing.xxl),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) => _SiteRow(site: visible[index]),
                  ),
          ),
        ],
      ),
    );
  }

  String _emptyMessage(AppLocalizations l10n) {
    if (state.query.trim().isNotEmpty) {
      return l10n.sitesEmptySearch;
    }
    return switch (state.filter) {
      SitesFilter.active => l10n.sitesEmptyActive,
      SitesFilter.archived => l10n.sitesEmptyArchived,
      SitesFilter.all => l10n.sitesEmptyAll,
    };
  }
}

/// One site: code, name, status chip and the row menu.
class _SiteRow extends StatelessWidget {
  const _SiteRow({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(site.name),
        subtitle: Text(site.code),
        leading: _StatusChip(isActive: site.isActive),
        trailing: PopupMenuButton<_SiteAction>(
          tooltip: l10n.siteActions,
          onSelected: (action) => _handleSiteAction(context, site, action),
          itemBuilder: (context) => [
            PopupMenuItem(value: _SiteAction.edit, child: Text(l10n.siteEdit)),
            if (site.isActive)
              PopupMenuItem(value: _SiteAction.archive, child: Text(l10n.siteArchive))
            else
              PopupMenuItem(value: _SiteAction.restore, child: Text(l10n.siteRestore)),
          ],
        ),
      ),
    );
  }
}

/// Container chip that always carries a text label, never color alone.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<AppStatusColors>()!;
    final radii = theme.extension<AppRadii>()!;
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
      decoration: BoxDecoration(
        color: isActive ? status.approvedContainer : status.archivedContainer,
        borderRadius: BorderRadius.circular(radii.sm),
      ),
      child: Text(
        isActive ? l10n.siteActive : l10n.siteArchived,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isActive ? status.approvedOnContainer : status.archivedOnContainer,
        ),
      ),
    );
  }
}
