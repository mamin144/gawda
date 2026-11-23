// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProfileRow _$ProfileRowFromJson(Map<String, dynamic> json) => _ProfileRow(
  id: json['id'] as String,
  fullName: json['full_name'] as String,
  role: json['role'] as String,
  isActive: json['is_active'] as bool,
);

Map<String, dynamic> _$ProfileRowToJson(_ProfileRow instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'role': instance.role,
      'is_active': instance.isActive,
    };
