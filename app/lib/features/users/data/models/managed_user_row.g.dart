// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'managed_user_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ManagedUserRow _$ManagedUserRowFromJson(Map<String, dynamic> json) => _ManagedUserRow(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String,
  role: json['role'] as String,
  isActive: json['is_active'] as bool,
  invitePending: json['invite_pending'] as bool,
  siteIds: (json['site_ids'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$ManagedUserRowToJson(_ManagedUserRow instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'full_name': instance.fullName,
  'role': instance.role,
  'is_active': instance.isActive,
  'invite_pending': instance.invitePending,
  'site_ids': instance.siteIds,
};
