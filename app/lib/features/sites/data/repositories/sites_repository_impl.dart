import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/site.dart';
import '../../domain/repositories/sites_repository.dart';
import '../models/site_row.dart';
import '../services/sites_service.dart';

class SitesRepositoryImpl implements SitesRepository {
  SitesRepositoryImpl(this._service);

  final SitesService _service;

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

  /// Sends only `is_active`; the database derives `archived_at` (R3).
  @override
  Future<Result<Site>> setArchived(String id, {required bool archived}) => _guard(
    () async => _toSite(await _service.updateSite(id, {'is_active': !archived})),
  );

  Site _toSite(Map<String, dynamic> row) => SiteRow.fromJson(row).toDomain();

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } catch (error) {
      return Left(mapExceptionToFailure(error));
    }
  }
}
