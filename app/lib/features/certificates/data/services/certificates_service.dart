import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw access to `public.certificates`, `public.attachments` and the private
/// `certificates` storage bucket. Throws Supabase exceptions; the repository
/// maps them to `AppFailure`.
abstract interface class CertificatesService {
  Future<List<Map<String, dynamic>>> fetchForSite(String siteId);
  Future<Map<String, dynamic>> fetchById(String id);
  Future<Map<String, dynamic>> insertCertificate(Map<String, dynamic> values);
  Future<Map<String, dynamic>> updateCertificate(String id, Map<String, dynamic> values);

  /// Soft-deletes through the `delete_certificate` RPC (draft/returned only).
  Future<Map<String, dynamic>> deleteCertificate(String id);

  Future<Map<String, dynamic>> submitCertificate(String id);

  /// Attachments of [certificateId] that are not soft-deleted.
  Future<List<Map<String, dynamic>>> fetchAttachments(String certificateId);
  Future<Map<String, dynamic>> insertAttachment(Map<String, dynamic> values);

  /// Soft-deletes through the `remove_attachment` RPC; the object is kept.
  Future<Map<String, dynamic>> removeAttachment(String id);

  /// Uploads [bytes] to [storagePath] in the private `certificates` bucket.
  Future<void> uploadFile(String storagePath, Uint8List bytes, String mime);

  /// Returns a short-lived signed URL for [storagePath].
  Future<String> signedUrl(String storagePath);

  /// Invokes the `finalize-certificate` Edge Function.
  Future<Map<String, dynamic>> finalizeCertificate(String certificateId);
}

class SupabaseCertificatesService implements CertificatesService {
  SupabaseCertificatesService(this._client);

  final SupabaseClient _client;

  static const _certColumns =
      'id, site_id, certificate_date, period_year, period_month, period_half, '
      'amount, notes, status, return_note, created_by, submitted_at, locked_at, '
      'deleted_at, created_at, updated_at';
  static const _attColumns =
      'id, certificate_id, kind, storage_path, file_name, mime, size_bytes, '
      'sha256, uploaded_by, uploaded_at, deleted_at, deleted_by, delete_reason';

  @override
  Future<List<Map<String, dynamic>>> fetchForSite(String siteId) async {
    final rows = await _client
        .from('certificates')
        .select(_certColumns)
        .eq('site_id', siteId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> fetchById(String id) async {
    final row = await _client.from('certificates').select(_certColumns).eq('id', id).single();
    return row;
  }

  @override
  Future<Map<String, dynamic>> insertCertificate(Map<String, dynamic> values) async {
    final row = await _client.from('certificates').insert(values).select(_certColumns).single();
    return row;
  }

  @override
  Future<Map<String, dynamic>> updateCertificate(String id, Map<String, dynamic> values) async {
    final row = await _client
        .from('certificates')
        .update(values)
        .eq('id', id)
        .select(_certColumns)
        .single();
    return row;
  }

  @override
  Future<Map<String, dynamic>> deleteCertificate(String id) =>
      _client.rpc<Map<String, dynamic>>('delete_certificate', params: {'p_id': id});

  @override
  Future<Map<String, dynamic>> submitCertificate(String id) async {
    final row = await _client.rpc<Map<String, dynamic>>('submit_certificate', params: {'p_id': id});
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAttachments(String certificateId) async {
    final rows = await _client
        .from('attachments')
        .select(_attColumns)
        .eq('certificate_id', certificateId)
        .isFilter('deleted_at', null)
        .order('uploaded_at', ascending: true);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> insertAttachment(Map<String, dynamic> values) async {
    final row = await _client.from('attachments').insert(values).select(_attColumns).single();
    return row;
  }

  @override
  Future<Map<String, dynamic>> removeAttachment(String id) =>
      _client.rpc<Map<String, dynamic>>('remove_attachment', params: {'p_id': id});

  @override
  Future<void> uploadFile(String storagePath, Uint8List bytes, String mime) async {
    await _client.storage
        .from('certificates')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: mime, upsert: false),
        );
  }

  @override
  Future<String> signedUrl(String storagePath) async {
    return _client.storage.from('certificates').createSignedUrl(storagePath, 60 * 5);
  }

  @override
  Future<Map<String, dynamic>> finalizeCertificate(String certificateId) async {
    final response = await _client.functions.invoke(
      'finalize-certificate',
      body: {'certificate_id': certificateId},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FormatException('finalize-certificate: unexpected response body', data);
  }
}
