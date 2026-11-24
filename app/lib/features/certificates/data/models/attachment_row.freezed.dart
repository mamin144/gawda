// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttachmentRow {

 String get id;@JsonKey(name: 'certificate_id') String get certificateId; String get kind;@JsonKey(name: 'storage_path') String get storagePath;@JsonKey(name: 'file_name') String get fileName; String get mime;@JsonKey(name: 'size_bytes') int get sizeBytes; String get sha256;@JsonKey(name: 'uploaded_by') String get uploadedBy;@JsonKey(name: 'uploaded_at') DateTime get uploadedAt;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;@JsonKey(name: 'deleted_by') String? get deletedBy;@JsonKey(name: 'delete_reason') String? get deleteReason;
/// Create a copy of AttachmentRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentRowCopyWith<AttachmentRow> get copyWith => _$AttachmentRowCopyWithImpl<AttachmentRow>(this as AttachmentRow, _$identity);

  /// Serializes this AttachmentRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AttachmentRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.certificateId, _this.certificateId) || other.certificateId == _this.certificateId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.storagePath, _this.storagePath) || other.storagePath == _this.storagePath)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.mime, _this.mime) || other.mime == _this.mime)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.uploadedBy, _this.uploadedBy) || other.uploadedBy == _this.uploadedBy)&&(identical(other.uploadedAt, _this.uploadedAt) || other.uploadedAt == _this.uploadedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.deletedBy, _this.deletedBy) || other.deletedBy == _this.deletedBy)&&(identical(other.deleteReason, _this.deleteReason) || other.deleteReason == _this.deleteReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AttachmentRow;
  return Object.hash(runtimeType,_this.id,_this.certificateId,_this.kind,_this.storagePath,_this.fileName,_this.mime,_this.sizeBytes,_this.sha256,_this.uploadedBy,_this.uploadedAt,_this.deletedAt,_this.deletedBy,_this.deleteReason);
}

@override
String toString() {
  final _this = this as AttachmentRow;
  return 'AttachmentRow(id: ${_this.id}, certificateId: ${_this.certificateId}, kind: ${_this.kind}, storagePath: ${_this.storagePath}, fileName: ${_this.fileName}, mime: ${_this.mime}, sizeBytes: ${_this.sizeBytes}, sha256: ${_this.sha256}, uploadedBy: ${_this.uploadedBy}, uploadedAt: ${_this.uploadedAt}, deletedAt: ${_this.deletedAt}, deletedBy: ${_this.deletedBy}, deleteReason: ${_this.deleteReason})';
}


}

/// @nodoc
abstract mixin class $AttachmentRowCopyWith<$Res>  {
  factory $AttachmentRowCopyWith(AttachmentRow value, $Res Function(AttachmentRow) _then) = _$AttachmentRowCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'certificate_id') String certificateId, String kind,@JsonKey(name: 'storage_path') String storagePath,@JsonKey(name: 'file_name') String fileName, String mime,@JsonKey(name: 'size_bytes') int sizeBytes, String sha256,@JsonKey(name: 'uploaded_by') String uploadedBy,@JsonKey(name: 'uploaded_at') DateTime uploadedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'deleted_by') String? deletedBy,@JsonKey(name: 'delete_reason') String? deleteReason
});




}
/// @nodoc
class _$AttachmentRowCopyWithImpl<$Res>
    implements $AttachmentRowCopyWith<$Res> {
  _$AttachmentRowCopyWithImpl(this._self, this._then);

  final AttachmentRow _self;
  final $Res Function(AttachmentRow) _then;

/// Create a copy of AttachmentRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? certificateId = null,Object? kind = null,Object? storagePath = null,Object? fileName = null,Object? mime = null,Object? sizeBytes = null,Object? sha256 = null,Object? uploadedBy = null,Object? uploadedAt = null,Object? deletedAt = freezed,Object? deletedBy = freezed,Object? deleteReason = freezed,}) {
  return _then(AttachmentRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,certificateId: null == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mime: null == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedBy: freezed == deletedBy ? _self.deletedBy : deletedBy // ignore: cast_nullable_to_non_nullable
as String?,deleteReason: freezed == deleteReason ? _self.deleteReason : deleteReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AttachmentRow].
extension AttachmentRowPatterns on AttachmentRow {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttachmentRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttachmentRow() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttachmentRow value)  $default,){
final _that = this;
switch (_that) {
case _AttachmentRow():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttachmentRow value)?  $default,){
final _that = this;
switch (_that) {
case _AttachmentRow() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'certificate_id')  String certificateId,  String kind, @JsonKey(name: 'storage_path')  String storagePath, @JsonKey(name: 'file_name')  String fileName,  String mime, @JsonKey(name: 'size_bytes')  int sizeBytes,  String sha256, @JsonKey(name: 'uploaded_by')  String uploadedBy, @JsonKey(name: 'uploaded_at')  DateTime uploadedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'deleted_by')  String? deletedBy, @JsonKey(name: 'delete_reason')  String? deleteReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttachmentRow() when $default != null:
return $default(_that.id,_that.certificateId,_that.kind,_that.storagePath,_that.fileName,_that.mime,_that.sizeBytes,_that.sha256,_that.uploadedBy,_that.uploadedAt,_that.deletedAt,_that.deletedBy,_that.deleteReason);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'certificate_id')  String certificateId,  String kind, @JsonKey(name: 'storage_path')  String storagePath, @JsonKey(name: 'file_name')  String fileName,  String mime, @JsonKey(name: 'size_bytes')  int sizeBytes,  String sha256, @JsonKey(name: 'uploaded_by')  String uploadedBy, @JsonKey(name: 'uploaded_at')  DateTime uploadedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'deleted_by')  String? deletedBy, @JsonKey(name: 'delete_reason')  String? deleteReason)  $default,) {final _that = this;
switch (_that) {
case _AttachmentRow():
return $default(_that.id,_that.certificateId,_that.kind,_that.storagePath,_that.fileName,_that.mime,_that.sizeBytes,_that.sha256,_that.uploadedBy,_that.uploadedAt,_that.deletedAt,_that.deletedBy,_that.deleteReason);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'certificate_id')  String certificateId,  String kind, @JsonKey(name: 'storage_path')  String storagePath, @JsonKey(name: 'file_name')  String fileName,  String mime, @JsonKey(name: 'size_bytes')  int sizeBytes,  String sha256, @JsonKey(name: 'uploaded_by')  String uploadedBy, @JsonKey(name: 'uploaded_at')  DateTime uploadedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'deleted_by')  String? deletedBy, @JsonKey(name: 'delete_reason')  String? deleteReason)?  $default,) {final _that = this;
switch (_that) {
case _AttachmentRow() when $default != null:
return $default(_that.id,_that.certificateId,_that.kind,_that.storagePath,_that.fileName,_that.mime,_that.sizeBytes,_that.sha256,_that.uploadedBy,_that.uploadedAt,_that.deletedAt,_that.deletedBy,_that.deleteReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttachmentRow implements AttachmentRow {
  const _AttachmentRow({required this.id, @JsonKey(name: 'certificate_id') required this.certificateId, required this.kind, @JsonKey(name: 'storage_path') required this.storagePath, @JsonKey(name: 'file_name') required this.fileName, required this.mime, @JsonKey(name: 'size_bytes') required this.sizeBytes, required this.sha256, @JsonKey(name: 'uploaded_by') required this.uploadedBy, @JsonKey(name: 'uploaded_at') required this.uploadedAt, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'deleted_by') this.deletedBy, @JsonKey(name: 'delete_reason') this.deleteReason});
  factory _AttachmentRow.fromJson(Map<String, dynamic> json) => _$AttachmentRowFromJson(json);

@override final  String id;
@override@JsonKey(name: 'certificate_id') final  String certificateId;
@override final  String kind;
@override@JsonKey(name: 'storage_path') final  String storagePath;
@override@JsonKey(name: 'file_name') final  String fileName;
@override final  String mime;
@override@JsonKey(name: 'size_bytes') final  int sizeBytes;
@override final  String sha256;
@override@JsonKey(name: 'uploaded_by') final  String uploadedBy;
@override@JsonKey(name: 'uploaded_at') final  DateTime uploadedAt;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;
@override@JsonKey(name: 'deleted_by') final  String? deletedBy;
@override@JsonKey(name: 'delete_reason') final  String? deleteReason;

/// Create a copy of AttachmentRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentRowCopyWith<_AttachmentRow> get copyWith => __$AttachmentRowCopyWithImpl<_AttachmentRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttachmentRow&&(identical(other.id, id) || other.id == id)&&(identical(other.certificateId, certificateId) || other.certificateId == certificateId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.deletedBy, deletedBy) || other.deletedBy == deletedBy)&&(identical(other.deleteReason, deleteReason) || other.deleteReason == deleteReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,certificateId,kind,storagePath,fileName,mime,sizeBytes,sha256,uploadedBy,uploadedAt,deletedAt,deletedBy,deleteReason);
}

@override
String toString() {
    return 'AttachmentRow(id: $id, certificateId: $certificateId, kind: $kind, storagePath: $storagePath, fileName: $fileName, mime: $mime, sizeBytes: $sizeBytes, sha256: $sha256, uploadedBy: $uploadedBy, uploadedAt: $uploadedAt, deletedAt: $deletedAt, deletedBy: $deletedBy, deleteReason: $deleteReason)';
}


}

/// @nodoc
abstract mixin class _$AttachmentRowCopyWith<$Res> implements $AttachmentRowCopyWith<$Res> {
  factory _$AttachmentRowCopyWith(_AttachmentRow value, $Res Function(_AttachmentRow) _then) = __$AttachmentRowCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'certificate_id') String certificateId, String kind,@JsonKey(name: 'storage_path') String storagePath,@JsonKey(name: 'file_name') String fileName, String mime,@JsonKey(name: 'size_bytes') int sizeBytes, String sha256,@JsonKey(name: 'uploaded_by') String uploadedBy,@JsonKey(name: 'uploaded_at') DateTime uploadedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'deleted_by') String? deletedBy,@JsonKey(name: 'delete_reason') String? deleteReason
});




}
/// @nodoc
class __$AttachmentRowCopyWithImpl<$Res>
    implements _$AttachmentRowCopyWith<$Res> {
  __$AttachmentRowCopyWithImpl(this._self, this._then);

  final _AttachmentRow _self;
  final $Res Function(_AttachmentRow) _then;

/// Create a copy of AttachmentRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? certificateId = null,Object? kind = null,Object? storagePath = null,Object? fileName = null,Object? mime = null,Object? sizeBytes = null,Object? sha256 = null,Object? uploadedBy = null,Object? uploadedAt = null,Object? deletedAt = freezed,Object? deletedBy = freezed,Object? deleteReason = freezed,}) {
  return _then(_AttachmentRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,certificateId: null == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mime: null == mime ? _self.mime : mime // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,uploadedBy: null == uploadedBy ? _self.uploadedBy : uploadedBy // ignore: cast_nullable_to_non_nullable
as String,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as DateTime,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedBy: freezed == deletedBy ? _self.deletedBy : deletedBy // ignore: cast_nullable_to_non_nullable
as String?,deleteReason: freezed == deleteReason ? _self.deleteReason : deleteReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
