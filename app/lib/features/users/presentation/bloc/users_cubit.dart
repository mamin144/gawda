import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/domain/repositories/sites_repository.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/users_repository.dart';

/// Admin users list. Filtering and search are client-side over
/// [UsersRepository.list]. Each action returns `true` on success and reloads
/// the list; on failure it returns `false` and the failure is readable from
/// [UsersLoaded.actionError].
sealed class UsersState {
  const UsersState();
}

/// First load in progress (no list yet).
final class UsersLoading extends UsersState {
  const UsersLoading();

  @override
  bool operator ==(Object other) => other is UsersLoading;

  @override
  int get hashCode => (UsersLoading).hashCode;
}

/// The full list from the server plus the client-side search and the active
/// sites the admin may assign to a site user.
final class UsersLoaded extends UsersState {
  const UsersLoaded({
    required this.users,
    this.activeSites = const [],
    this.query = '',
    this.actionError,
  });

  final List<ManagedUser> users;
  final List<Site> activeSites;
  final String query;
  final AppFailure? actionError;

  /// Users matching [query] (name or email, case-insensitive, trimmed).
  List<ManagedUser> get visibleUsers {
    final needle = query.trim().toLowerCase();
    return [
      for (final user in users)
        if (needle.isEmpty ||
            user.fullName.toLowerCase().contains(needle) ||
            user.email.toLowerCase().contains(needle))
          user,
    ];
  }

  UsersLoaded copyWith({
    List<ManagedUser>? users,
    List<Site>? activeSites,
    String? query,
  }) => UsersLoaded(
    users: users ?? this.users,
    activeSites: activeSites ?? this.activeSites,
    query: query ?? this.query,
  );

  UsersLoaded withActionError(AppFailure? failure) => UsersLoaded(
    users: users,
    activeSites: activeSites,
    query: query,
    actionError: failure,
  );

  @override
  bool operator ==(Object other) =>
      other is UsersLoaded &&
      listEquals(other.users, users) &&
      listEquals(other.activeSites, activeSites) &&
      other.query == query &&
      other.actionError == actionError;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(users), Object.hashAll(activeSites), query, actionError);
}

/// The first load failed; the page offers a retry.
final class UsersError extends UsersState {
  const UsersError(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) => other is UsersError && other.failure == failure;

  @override
  int get hashCode => Object.hash(UsersError, failure);
}

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._usersRepo, this._sitesRepo) : super(const UsersLoading());

  final UsersRepository _usersRepo;
  final SitesRepository _sitesRepo;

  Future<void> load() async {
    emit(const UsersLoading());
    final usersResult = await _usersRepo.list();
    final sitesResult = await _sitesRepo.list();
    if (isClosed) {
      return;
    }
    if (usersResult case Left(value: final failure)) {
      emit(UsersError(failure));
      return;
    }
    if (sitesResult case Left(value: final failure)) {
      emit(UsersError(failure));
      return;
    }
    final users = usersResult.getOrElse((_) => const <ManagedUser>[]);
    final allSites = sitesResult.getOrElse((_) => const <Site>[]);
    final activeSites = allSites.where((site) => site.isActive).toList();
    emit(UsersLoaded(users: users, activeSites: activeSites));
  }

  void setQuery(String query) {
    if (state case final UsersLoaded loaded) {
      emit(loaded.copyWith(query: query));
    }
  }

  Future<bool> invite({
    required String email,
    required String fullName,
    required UserRole role,
    required List<String> siteIds,
  }) => _run(
    () => _usersRepo.invite(
      email: email,
      fullName: fullName,
      role: role,
      siteIds: siteIds,
    ),
  );

  Future<bool> update(
    String id, {
    required String fullName,
    required UserRole role,
    required bool isActive,
  }) => _run(
    () => _usersRepo.update(
      id,
      fullName: fullName,
      role: role,
      isActive: isActive,
    ),
  );

  Future<bool> setSites(String id, List<String> siteIds) =>
      _run(() => _usersRepo.setSites(id, siteIds));

  Future<bool> _run<T>(Future<Result<T>> Function() action) async {
    final result = await action();
    if (isClosed) {
      return result.isRight();
    }
    if (result case Left(value: final failure)) {
      if (state case final UsersLoaded loaded) {
        emit(loaded.withActionError(failure));
      }
      return false;
    }
    await _reload();
    return true;
  }

  /// Refreshes the users only, keeping the active sites, filter and query.
  Future<void> _reload() async {
    final result = await _usersRepo.list();
    if (isClosed) {
      return;
    }
    final current = state;
    result.match(
      (failure) {
        if (current is UsersLoaded) {
          emit(current.withActionError(failure));
        } else {
          emit(UsersError(failure));
        }
      },
      (users) => emit(
        current is UsersLoaded ? current.copyWith(users: users) : UsersLoaded(users: users),
      ),
    );
  }
}
