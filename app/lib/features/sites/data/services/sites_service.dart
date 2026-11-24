import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw access to `public.sites`. Throws Supabase exceptions; the repository
/// maps them to `AppFailure`. RLS restricts writes to admins.
abstract interface class SitesService {
  Future<List<Map<String, dynamic>>> fetchSites();
  Future<Map<String, dynamic>> insertSite(Map<String, dynamic> values);
  Future<Map<String, dynamic>> updateSite(String id, Map<String, dynamic> values);
}

class SupabaseSitesService implements SitesService {
  SupabaseSitesService(this._client);

  static const _columns = 'id, code, name, is_active, archived_at';

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchSites() =>
      _client.from('sites').select(_columns).order('code', ascending: true);

  @override
  Future<Map<String, dynamic>> insertSite(Map<String, dynamic> values) =>
      _client.from('sites').insert(values).select(_columns).single();

  @override
  Future<Map<String, dynamic>> updateSite(String id, Map<String, dynamic> values) =>
      _client.from('sites').update(values).eq('id', id).select(_columns).single();
}
