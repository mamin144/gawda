// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Attachment {

 String get id; String get certificateId; AttachmentKind get kind; String get storagePath; String get fileName; String get mime; int get sizeBytes; String get sha256; String get uploadedBy; DateTime get uploadedAt; DateTime? get deletedAt; String? get deletedBy; String? get deleteReason;
/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentCopyWith<Attachment> get copyWith => _$AttachmentCopyWithImpl<Attachment>(this as Attachment, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Attachment;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attachment&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.certificateId, _this.certificateId) || other.certificateId == _this.certificateId)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.storagePath, _this.storagePath) || other.storagePath == _this.storagePath)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.mime, _this.mime) || other.mime == _this.mime)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.uploadedBy, _this.uploadedBy) || other.uploadedBy == _this.uploadedBy)&&(identical(other.uploadedAt, _this.uploadedAt) || other.uploadedAt == _this.uploadedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.deletedBy, _this.deletedBy) || other.deletedBy == _this.deletedBy)&&(identical(other.deleteReason, _this.deleteReason) || other.deleteReason == _this.deleteReason));
}


@override
int get hashCode {
  final _this = this as Attachment;
  return Object.hash(runtimeType,_this.id,_this.certificateId,_this.kind,_this.storagePath,_this.fileName,_this.mime,_this.sizeBytes,_this.sha256,_this.uploadedBy,_this.uploadedAt,_this.deletedAt,_this.deletedBy,_this.deleteReason);
}

@override
String toString() {
  final _this = this as Attachment;
  return 'Attachment(id: ${_this.id}, certificateId: ${_this.certificateId}, kind: ${_this.kind}, storagePath: ${_this.storagePath}, fileName: ${_this.fileName}, mime: ${_this.mime}, sizeBytes: ${_this.sizeBytes}, sha256: ${_this.sha256}, uploadedBy: ${_this.uploadedBy}, uploadedAt: ${_this.uploadedAt}, deletedAt: ${_this.deletedAt}, deletedBy: ${_this.deletedBy}, deleteReason: ${_this.deleteReason})';
}


}

/// @nodoc
abstract mixin class $AttachmentCopyWith<$Res>  {
  factory $AttachmentCopyWith(Attachment value, $Res Function(Attachment) _then) = _$AttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String certificateId, AttachmentKind kind, String storagePath, String fileName, String mime, int sizeBytes, String sha256, String uploadedBy, DateTime uploadedAt, DateTime? deletedAt, String? deletedBy, String? deleteReason
});




}
/// @nodoc
class _$AttachmentCopyWithImpl<$Res>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._self, this._then);

  final Attachment _self;
  final $Res Function(Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? certificateId = null,Object? kind = null,Object? storagePath = null,Object? fileName = null,Object? mime = null,Object? sizeBytes = null,Object? sha256 = null,Object? uploadedBy = null,Object? uploadedAt = null,Object? deletedAt = freezed,Object? deletedBy = freezed,Object? deleteReason = freezed,}) {
  return _then(Attachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,certificateId: null == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttachmentKind,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [Attachment].
extension AttachmentPatterns on Attachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attachment value)  $default,){
final _that = this;
switch (_that) {
case _Attachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attachment value)?  $default,){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String certificateId,  AttachmentKind kind,  String storagePath,  String fileName,  String mime,  int sizeBytes,  String sha256,  String uploadedBy,  DateTime uploadedAt,  DateTime? deletedAt,  String? deletedBy,  String? deleteReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String certificateId,  AttachmentKind kind,  String storagePath,  String fileName,  String mime,  int sizeBytes,  String sha256,  String uploadedBy,  DateTime uploadedAt,  DateTime? deletedAt,  String? deletedBy,  String? deleteReason)  $default,) {final _that = this;
switch (_that) {
case _Attachment():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String certificateId,  AttachmentKind kind,  String storagePath,  String fileName,  String mime,  int sizeBytes,  String sha256,  String uploadedBy,  DateTime uploadedAt,  DateTime? deletedAt,  String? deletedBy,  String? deleteReason)?  $default,) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.id,_that.certificateId,_that.kind,_that.storagePath,_that.fileName,_that.mime,_that.sizeBytes,_that.sha256,_that.uploadedBy,_that.uploadedAt,_that.deletedAt,_that.deletedBy,_that.deleteReason);case _:
  return null;

}
}

}

/// @nodoc


class _Attachment implements Attachment {
  const _Attachment({required this.id, required this.certificateId, required this.kind, required this.storagePath, required this.fileName, required this.mime, required this.sizeBytes, required this.sha256, required this.uploadedBy, required this.uploadedAt, this.deletedAt, this.deletedBy, this.deleteReason});
  

@override final  String id;
@override final  String certificateId;
@override final  AttachmentKind kind;
@override final  String storagePath;
@override final  String fileName;
@override final  String mime;
@override final  int sizeBytes;
@override final  String sha256;
@override final  String uploadedBy;
@override final  DateTime uploadedAt;
@override final  DateTime? deletedAt;
@override final  String? deletedBy;
@override final  String? deleteReason;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentCopyWith<_Attachment> get copyWith => __$AttachmentCopyWithImpl<_Attachment>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attachment&&(identical(other.id, id) || other.id == id)&&(identical(other.certificateId, certificateId) || other.certificateId == certificateId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mime, mime) || other.mime == mime)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.uploadedBy, uploadedBy) || other.uploadedBy == uploadedBy)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.deletedBy, deletedBy) || other.deletedBy == deletedBy)&&(identical(other.deleteReason, deleteReason) || other.deleteReason == deleteReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,certificateId,kind,storagePath,fileName,mime,sizeBytes,sha256,uploadedBy,uploadedAt,deletedAt,deletedBy,deleteReason);
}

@override
String toString() {
    return 'Attachment(id: $id, certificateId: $certificateId, kind: $kind, storagePath: $storagePath, fileName: $fileName, mime: $mime, sizeBytes: $sizeBytes, sha256: $sha256, uploadedBy: $uploadedBy, uploadedAt: $uploadedAt, deletedAt: $deletedAt, deletedBy: $deletedBy, deleteReason: $deleteReason)';
}


}

/// @nodoc
abstract mixin class _$AttachmentCopyWith<$Res> implements $AttachmentCopyWith<$Res> {
  factory _$AttachmentCopyWith(_Attachment value, $Res Function(_Attachment) _then) = __$AttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String certificateId, AttachmentKind kind, String storagePath, String fileName, String mime, int sizeBytes, String sha256, String uploadedBy, DateTime uploadedAt, DateTime? deletedAt, String? deletedBy, String? deleteReason
});




}
/// @nodoc
class __$AttachmentCopyWithImpl<$Res>
    implements _$AttachmentCopyWith<$Res> {
  __$AttachmentCopyWithImpl(this._self, this._then);

  final _Attachment _self;
  final $Res Function(_Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? certificateId = null,Object? kind = null,Object? storagePath = null,Object? fileName = null,Object? mime = null,Object? sizeBytes = null,Object? sha256 = null,Object? uploadedBy = null,Object? uploadedAt = null,Object? deletedAt = freezed,Object? deletedBy = freezed,Object? deleteReason = freezed,}) {
  return _then(_Attachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,certificateId: null == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AttachmentKind,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
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
