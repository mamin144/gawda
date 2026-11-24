import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/site.dart';

part 'site_row.freezed.dart';
part 'site_row.g.dart';

/// Raw `public.sites` row — exactly the columns selected from the database:
/// id, code, name, is_active, archived_at.
@freezed
abstract class SiteRow with _$SiteRow {
  const factory SiteRow({
    required String id,
    required String code,
    required String name,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'archived_at') DateTime? archivedAt,
  }) = _SiteRow;

  factory SiteRow.fromJson(Map<String, dynamic> json) => _$SiteRowFromJson(json);
}

/// Mapping kept out of the freezed class body (see `ProfileRowMapping`).
extension SiteRowMapping on SiteRow {
  Site toDomain() =>
      Site(id: id, code: code, name: name, isActive: isActive, archivedAt: archivedAt);
}
