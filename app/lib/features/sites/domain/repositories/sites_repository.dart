import '../../../../core/error/result.dart';
import '../entities/site.dart';

/// Admin management of sites. RLS and database guards enforce authorization
/// and business rules; failures come back as [Result] lefts.
abstract interface class SitesRepository {
  Future<Result<List<Site>>> list();
  Future<Result<Site>> create({required String code, required String name});
  Future<Result<Site>> update(String id, {required String code, required String name});
  Future<Result<Site>> setArchived(String id, {required bool archived});
}
