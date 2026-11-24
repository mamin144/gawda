// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SiteRow _$SiteRowFromJson(Map<String, dynamic> json) => _SiteRow(
  id: json['id'] as String,
  code: json['code'] as String,
  name: json['name'] as String,
  isActive: json['is_active'] as bool,
  archivedAt: json['archived_at'] == null ? null : DateTime.parse(json['archived_at'] as String),
);

Map<String, dynamic> _$SiteRowToJson(_SiteRow instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'is_active': instance.isActive,
  'archived_at': instance.archivedAt?.toIso8601String(),
};
