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
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/session_cubit.dart';
import '../../../sites/domain/repositories/sites_repository.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/users_repository.dart';
import '../bloc/users_cubit.dart';
import '../widgets/edit_user_dialog.dart';
import '../widgets/invite_user_dialog.dart';

/// Admin users management screen. Rendered inside the admin shell, so it owns
/// no Scaffold or AppBar; the invite action is a FAB-sized button in the body.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UsersCubit(
        context.read<UsersRepository>(),
        context.read<SitesRepository>(),
      )..load(),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        return Stack(
          children: [
            Positioned.fill(child: _buildBody(context, state)),
            if (state is UsersLoaded)
              PositionedDirectional(
                end: spacing.xl,
                bottom: spacing.xl,
                child: FloatingActionButton(
                  tooltip: l10n.userInvite,
                  onPressed: () => _openInvite(context),
                  child: const Icon(Icons.person_add),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, UsersState state) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<UsersCubit>();
    return switch (state) {
      UsersLoading() => const LoadingView(),
      UsersError(:final failure) => ErrorView(
        message: failureMessage(failure, l10n),
        onRetry: cubit.load,
      ),
      UsersLoaded() => _LoadedView(state: state),
    };
  }
}

Future<void> _openInvite(BuildContext context) async {
  final cubit = context.read<UsersCubit>();
  final state = cubit.state;
  if (state is! UsersLoaded) {
    return;
  }
  await showInviteUserDialog(
    context,
    sites: state.activeSites,
    onSubmit:
        ({
          required String email,
          required String fullName,
          required UserRole role,
          required List<String> siteIds,
        }) async {
          final succeeded = await cubit.invite(
            email: email,
            fullName: fullName,
            role: role,
            siteIds: siteIds,
          );
          if (succeeded) {
            return null;
          }
          final current = cubit.state;
          if (current is UsersLoaded) {
            return current.actionError ?? const ServerFailure();
          }
          return const ServerFailure();
        },
  );
}

Future<void> _openEdit(BuildContext context, ManagedUser user) async {
  final cubit = context.read<UsersCubit>();
  final state = cubit.state;
  if (state is! UsersLoaded) {
    return;
  }
  final sessionState = context.read<SessionCubit>().state;
  final currentUserId = sessionState is SessionAuthenticated ? sessionState.user.id : null;
  final isSelf = currentUserId == user.id;

  await showEditUserDialog(
    context,
    initial: user,
    activeSites: state.activeSites,
    isSelf: isSelf,
    onSubmit:
        ({
          required String fullName,
          required UserRole role,
          required bool isActive,
          required List<String> siteIds,
        }) async {
          // Promoting a site user to admin requires clearing their site links
          // first; the database guard rejects a promotion while links remain.
          if (user.role == UserRole.siteUser && role == UserRole.admin) {
            final cleared = await cubit.setSites(user.id, const <String>[]);
            if (!cleared) {
              return _actionFailure(cubit);
            }
          }
          final updated = await cubit.update(
            user.id,
            fullName: fullName,
            role: role,
            isActive: isActive,
          );
          if (!updated) {
            return _actionFailure(cubit);
          }
          final sitesChanged = role == UserRole.siteUser && !_sameSites(siteIds, user.siteIds);
          if (sitesChanged) {
            final saved = await cubit.setSites(user.id, siteIds);
            if (!saved) {
              return _actionFailure(cubit);
            }
          }
          return null;
        },
  );
}

AppFailure _actionFailure(UsersCubit cubit) {
  final current = cubit.state;
  if (current is UsersLoaded) {
    return current.actionError ?? const ServerFailure();
  }
  return const ServerFailure();
}

bool _sameSites(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  final sa = {...a};
  return b.every(sa.contains);
}

/// Search and list for a loaded users state.
class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final UsersLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<UsersCubit>();
    final visible = state.visibleUsers;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: cubit.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.usersSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          SizedBox(height: spacing.md),
          Expanded(
            child: visible.isEmpty
                ? EmptyView(
                    message: state.query.trim().isNotEmpty
                        ? l10n.usersEmptySearch
                        : l10n.usersEmpty,
                    icon: Icons.people_outline,
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(top: spacing.xs, bottom: spacing.xxxl + spacing.xxl),
                    itemCount: visible.length,
                    separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
                    itemBuilder: (context, index) => _UserRow(
                      user: visible[index],
                      onTap: () => _openEdit(context, visible[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One user: name, email, role, status chip and site count.
class _UserRow extends StatelessWidget {
  const _UserRow({required this.user, required this.onTap});

  final ManagedUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;
    final radii = theme.extension<AppRadii>()!;
    final status = theme.extension<AppStatusColors>()!;
    final l10n = AppLocalizations.of(context);

    final roleLabel = user.role == UserRole.admin ? l10n.userRoleAdmin : l10n.userRoleSiteUser;

    String chipLabel;
    Color chipColor;
    Color chipOnColor;
    if (user.invitePending) {
      chipLabel = l10n.userInvitePending;
      chipColor = status.needsReviewContainer;
      chipOnColor = status.needsReviewOnContainer;
    } else if (user.isActive) {
      chipLabel = l10n.userActive;
      chipColor = status.approvedContainer;
      chipOnColor = status.approvedOnContainer;
    } else {
      chipLabel = l10n.userInactive;
      chipColor = status.archivedContainer;
      chipOnColor = status.archivedOnContainer;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.email),
            SizedBox(height: spacing.xs),
            Wrap(
              spacing: spacing.sm,
              runSpacing: spacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(roleLabel),
                if (user.role == UserRole.siteUser) Text(l10n.userSiteCount(user.siteIds.length)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(radii.sm),
          ),
          child: Text(
            chipLabel,
            style: theme.textTheme.labelSmall?.copyWith(color: chipOnColor),
          ),
        ),
      ),
    );
  }
}
