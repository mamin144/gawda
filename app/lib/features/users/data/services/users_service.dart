import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw access for admin user management. Throws Supabase exceptions
/// (`PostgrestException`, `FunctionException`); the repository maps them to
/// `AppFailure`.
abstract interface class UsersService {
  /// Rows of the `admin_list_users()` RPC.
  Future<List<Map<String, dynamic>>> fetchUsers();

  /// Invokes the `admin-create-user` Edge Function and returns its JSON body.
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> body);

  /// Plain update of `public.profiles` by id.
  Future<void> updateProfile(String id, Map<String, dynamic> values);

  /// Calls a database RPC by name with named parameters.
  Future<Object?> rpc(String function, Map<String, dynamic> params);
}

class SupabaseUsersService implements UsersService {
  SupabaseUsersService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final rows = await _client.rpc<List<dynamic>>('admin_list_users');
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke('admin-create-user', body: body);
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FormatException('admin-create-user: unexpected response body', data);
  }

  @override
  Future<void> updateProfile(String id, Map<String, dynamic> values) async {
    await _client.from('profiles').update(values).eq('id', id).select('id').single();
  }

  @override
  Future<Object?> rpc(String function, Map<String, dynamic> params) =>
      _client.rpc<Object?>(function, params: params);
}
