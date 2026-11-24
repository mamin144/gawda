import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/site.dart';
import '../../domain/repositories/sites_repository.dart';

/// Which sites the list shows. The default is [active].
enum SitesFilter { active, archived, all }

sealed class SitesState {
  const SitesState();
}

/// First load in progress (no list yet).
final class SitesLoading extends SitesState {
  const SitesLoading();

  @override
  bool operator ==(Object other) => other is SitesLoading;

  @override
  int get hashCode => (SitesLoading).hashCode;
}

/// The full list from the server plus the client-side filter and search.
/// [actionError] holds the failure of the last create/update/archive action;
/// the list stays visible when an action fails.
final class SitesLoaded extends SitesState {
  const SitesLoaded({
    required this.sites,
    this.filter = SitesFilter.active,
    this.query = '',
    this.actionError,
  });

  final List<Site> sites;
  final SitesFilter filter;
  final String query;
  final AppFailure? actionError;

  /// Sites matching [filter] and [query] (code or name, case-insensitive, trimmed).
  List<Site> get visibleSites {
    final needle = query.trim().toLowerCase();
    return [
      for (final site in sites)
        if (_matchesFilter(site) &&
            (needle.isEmpty ||
                site.code.toLowerCase().contains(needle) ||
                site.name.toLowerCase().contains(needle)))
          site,
    ];
  }

  bool _matchesFilter(Site site) => switch (filter) {
    SitesFilter.active => site.isActive,
    SitesFilter.archived => !site.isActive,
    SitesFilter.all => true,
  };

  SitesLoaded copyWith({List<Site>? sites, SitesFilter? filter, String? query}) => SitesLoaded(
    sites: sites ?? this.sites,
    filter: filter ?? this.filter,
    query: query ?? this.query,
  );

  SitesLoaded withActionError(AppFailure? failure) =>
      SitesLoaded(sites: sites, filter: filter, query: query, actionError: failure);

  @override
  bool operator ==(Object other) =>
      other is SitesLoaded &&
      listEquals(other.sites, sites) &&
      other.filter == filter &&
      other.query == query &&
      other.actionError == actionError;

  @override
  int get hashCode => Object.hash(Object.hashAll(sites), filter, query, actionError);
}

/// The first load failed; the page offers a retry.
final class SitesError extends SitesState {
  const SitesError(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) => other is SitesError && other.failure == failure;

  @override
  int get hashCode => Object.hash(SitesError, failure);
}

/// Admin sites list. Filtering and search are client-side over [SitesRepository.list].
/// Each action returns `true` on success (and reloads the list); on failure it
/// returns `false` and the failure is readable from [SitesLoaded.actionError].
class SitesCubit extends Cubit<SitesState> {
  SitesCubit(this._repo) : super(const SitesLoading());

  final SitesRepository _repo;

  Future<void> load() async {
    emit(const SitesLoading());
    final result = await _repo.list();
    if (isClosed) {
      return;
    }
    result.match(
      (failure) => emit(SitesError(failure)),
      (sites) => emit(SitesLoaded(sites: sites)),
    );
  }

  void setFilter(SitesFilter filter) {
    if (state case final SitesLoaded loaded) {
      emit(loaded.copyWith(filter: filter));
    }
  }

  void setQuery(String query) {
    if (state case final SitesLoaded loaded) {
      emit(loaded.copyWith(query: query));
    }
  }

  Future<bool> create(String code, String name) => _run(() => _repo.create(code: code, name: name));

  Future<bool> update(String id, String code, String name) =>
      _run(() => _repo.update(id, code: code, name: name));

  Future<bool> setArchived(String id, {required bool archived}) =>
      _run(() => _repo.setArchived(id, archived: archived));

  Future<bool> _run(Future<Result<Site>> Function() action) async {
    final result = await action();
    if (isClosed) {
      return result.isRight();
    }
    if (result case Left(value: final failure)) {
      if (state case final SitesLoaded loaded) {
        emit(loaded.withActionError(failure));
      }
      return false;
    }
    await _reload();
    return true;
  }

  /// Refreshes the list keeping filter and query. A failed refresh keeps the
  /// previous list and reports the failure through `actionError`.
  Future<void> _reload() async {
    final result = await _repo.list();
    if (isClosed) {
      return;
    }
    final current = state;
    result.match(
      (failure) {
        if (current is SitesLoaded) {
          emit(current.withActionError(failure));
        } else {
          emit(SitesError(failure));
        }
      },
      (sites) => emit(
        current is SitesLoaded ? current.copyWith(sites: sites) : SitesLoaded(sites: sites),
      ),
    );
  }
}
