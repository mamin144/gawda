import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches the caller's own `profiles` row. RLS decides visibility;
/// the client never reads roles from `user_metadata`.
abstract interface class ProfileService {
  Future<Map<String, dynamic>> fetchProfile(String userId);
}

class SupabaseProfileService implements ProfileService {
  SupabaseProfileService(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> fetchProfile(String userId) => _client
      .from('profiles')
      .select('id, full_name, role, is_active')
      .eq('id', userId)
      .single();
}
