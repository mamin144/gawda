import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/site.dart';
import '../../domain/repositories/sites_repository.dart';
import '../models/site_row.dart';
import '../services/sites_service.dart';

class SitesRepositoryImpl implements SitesRepository {
  SitesRepositoryImpl(this._service, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final SitesService _service;
  final DateTime Function() _now;

  /// Rows arrive ordered by code from the service; order is preserved.
  @override
  Future<Result<List<Site>>> list() => _guard(() async {
    final rows = await _service.fetchSites();
    return rows.map(_toSite).toList(growable: false);
  });

  @override
  Future<Result<Site>> create({required String code, required String name}) =>
      _guard(() async => _toSite(await _service.insertSite({'code': code, 'name': name})));

  @override
  Future<Result<Site>> update(String id, {required String code, required String name}) =>
      _guard(() async => _toSite(await _service.updateSite(id, {'code': code, 'name': name})));

  /// `is_active` and `archived_at` always change together; the database
  /// rejects anything else with `archive_inconsistent`.
  @override
  Future<Result<Site>> setArchived(String id, {required bool archived}) => _guard(() async {
    final values = archived
        ? <String, dynamic>{'is_active': false, 'archived_at': _now().toUtc().toIso8601String()}
        : <String, dynamic>{'is_active': true, 'archived_at': null};
    return _toSite(await _service.updateSite(id, values));
  });

  Site _toSite(Map<String, dynamic> row) => SiteRow.fromJson(row).toDomain();

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
