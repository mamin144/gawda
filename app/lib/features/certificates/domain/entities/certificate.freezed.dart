// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Certificate {

 String get id; String get siteId; DateTime get certificateDate; int get periodYear; int get periodMonth; int get periodHalf;/// Decimal amount as a string to avoid floating-point drift.
 String get amount; String? get notes; CertificateStatus get status; String? get returnNote; String get createdBy; DateTime? get submittedAt; DateTime? get lockedAt; DateTime? get deletedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Certificate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateCopyWith<Certificate> get copyWith => _$CertificateCopyWithImpl<Certificate>(this as Certificate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Certificate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Certificate&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.siteId, _this.siteId) || other.siteId == _this.siteId)&&(identical(other.certificateDate, _this.certificateDate) || other.certificateDate == _this.certificateDate)&&(identical(other.periodYear, _this.periodYear) || other.periodYear == _this.periodYear)&&(identical(other.periodMonth, _this.periodMonth) || other.periodMonth == _this.periodMonth)&&(identical(other.periodHalf, _this.periodHalf) || other.periodHalf == _this.periodHalf)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.returnNote, _this.returnNote) || other.returnNote == _this.returnNote)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.submittedAt, _this.submittedAt) || other.submittedAt == _this.submittedAt)&&(identical(other.lockedAt, _this.lockedAt) || other.lockedAt == _this.lockedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as Certificate;
  return Object.hash(runtimeType,_this.id,_this.siteId,_this.certificateDate,_this.periodYear,_this.periodMonth,_this.periodHalf,_this.amount,_this.notes,_this.status,_this.returnNote,_this.createdBy,_this.submittedAt,_this.lockedAt,_this.deletedAt,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as Certificate;
  return 'Certificate(id: ${_this.id}, siteId: ${_this.siteId}, certificateDate: ${_this.certificateDate}, periodYear: ${_this.periodYear}, periodMonth: ${_this.periodMonth}, periodHalf: ${_this.periodHalf}, amount: ${_this.amount}, notes: ${_this.notes}, status: ${_this.status}, returnNote: ${_this.returnNote}, createdBy: ${_this.createdBy}, submittedAt: ${_this.submittedAt}, lockedAt: ${_this.lockedAt}, deletedAt: ${_this.deletedAt}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $CertificateCopyWith<$Res>  {
  factory $CertificateCopyWith(Certificate value, $Res Function(Certificate) _then) = _$CertificateCopyWithImpl;
@useResult
$Res call({
 String id, String siteId, DateTime certificateDate, int periodYear, int periodMonth, int periodHalf, String amount, String? notes, CertificateStatus status, String? returnNote, String createdBy, DateTime? submittedAt, DateTime? lockedAt, DateTime? deletedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$CertificateCopyWithImpl<$Res>
    implements $CertificateCopyWith<$Res> {
  _$CertificateCopyWithImpl(this._self, this._then);

  final Certificate _self;
  final $Res Function(Certificate) _then;

/// Create a copy of Certificate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? siteId = null,Object? certificateDate = null,Object? periodYear = null,Object? periodMonth = null,Object? periodHalf = null,Object? amount = null,Object? notes = freezed,Object? status = null,Object? returnNote = freezed,Object? createdBy = null,Object? submittedAt = freezed,Object? lockedAt = freezed,Object? deletedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(Certificate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,siteId: null == siteId ? _self.siteId : siteId // ignore: cast_nullable_to_non_nullable
as String,certificateDate: null == certificateDate ? _self.certificateDate : certificateDate // ignore: cast_nullable_to_non_nullable
as DateTime,periodYear: null == periodYear ? _self.periodYear : periodYear // ignore: cast_nullable_to_non_nullable
as int,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as int,periodHalf: null == periodHalf ? _self.periodHalf : periodHalf // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CertificateStatus,returnNote: freezed == returnNote ? _self.returnNote : returnNote // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lockedAt: freezed == lockedAt ? _self.lockedAt : lockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Certificate].
extension CertificatePatterns on Certificate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Certificate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Certificate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Certificate value)  $default,){
final _that = this;
switch (_that) {
case _Certificate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Certificate value)?  $default,){
final _that = this;
switch (_that) {
case _Certificate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String siteId,  DateTime certificateDate,  int periodYear,  int periodMonth,  int periodHalf,  String amount,  String? notes,  CertificateStatus status,  String? returnNote,  String createdBy,  DateTime? submittedAt,  DateTime? lockedAt,  DateTime? deletedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Certificate() when $default != null:
return $default(_that.id,_that.siteId,_that.certificateDate,_that.periodYear,_that.periodMonth,_that.periodHalf,_that.amount,_that.notes,_that.status,_that.returnNote,_that.createdBy,_that.submittedAt,_that.lockedAt,_that.deletedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String siteId,  DateTime certificateDate,  int periodYear,  int periodMonth,  int periodHalf,  String amount,  String? notes,  CertificateStatus status,  String? returnNote,  String createdBy,  DateTime? submittedAt,  DateTime? lockedAt,  DateTime? deletedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Certificate():
return $default(_that.id,_that.siteId,_that.certificateDate,_that.periodYear,_that.periodMonth,_that.periodHalf,_that.amount,_that.notes,_that.status,_that.returnNote,_that.createdBy,_that.submittedAt,_that.lockedAt,_that.deletedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String siteId,  DateTime certificateDate,  int periodYear,  int periodMonth,  int periodHalf,  String amount,  String? notes,  CertificateStatus status,  String? returnNote,  String createdBy,  DateTime? submittedAt,  DateTime? lockedAt,  DateTime? deletedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Certificate() when $default != null:
return $default(_that.id,_that.siteId,_that.certificateDate,_that.periodYear,_that.periodMonth,_that.periodHalf,_that.amount,_that.notes,_that.status,_that.returnNote,_that.createdBy,_that.submittedAt,_that.lockedAt,_that.deletedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Certificate implements Certificate {
  const _Certificate({required this.id, required this.siteId, required this.certificateDate, required this.periodYear, required this.periodMonth, required this.periodHalf, required this.amount, this.notes, required this.status, this.returnNote, required this.createdBy, this.submittedAt, this.lockedAt, this.deletedAt, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String siteId;
@override final  DateTime certificateDate;
@override final  int periodYear;
@override final  int periodMonth;
@override final  int periodHalf;
/// Decimal amount as a string to avoid floating-point drift.
@override final  String amount;
@override final  String? notes;
@override final  CertificateStatus status;
@override final  String? returnNote;
@override final  String createdBy;
@override final  DateTime? submittedAt;
@override final  DateTime? lockedAt;
@override final  DateTime? deletedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Certificate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateCopyWith<_Certificate> get copyWith => __$CertificateCopyWithImpl<_Certificate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Certificate&&(identical(other.id, id) || other.id == id)&&(identical(other.siteId, siteId) || other.siteId == siteId)&&(identical(other.certificateDate, certificateDate) || other.certificateDate == certificateDate)&&(identical(other.periodYear, periodYear) || other.periodYear == periodYear)&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.periodHalf, periodHalf) || other.periodHalf == periodHalf)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.returnNote, returnNote) || other.returnNote == returnNote)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.lockedAt, lockedAt) || other.lockedAt == lockedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,siteId,certificateDate,periodYear,periodMonth,periodHalf,amount,notes,status,returnNote,createdBy,submittedAt,lockedAt,deletedAt,createdAt,updatedAt);
}

@override
String toString() {
    return 'Certificate(id: $id, siteId: $siteId, certificateDate: $certificateDate, periodYear: $periodYear, periodMonth: $periodMonth, periodHalf: $periodHalf, amount: $amount, notes: $notes, status: $status, returnNote: $returnNote, createdBy: $createdBy, submittedAt: $submittedAt, lockedAt: $lockedAt, deletedAt: $deletedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CertificateCopyWith<$Res> implements $CertificateCopyWith<$Res> {
  factory _$CertificateCopyWith(_Certificate value, $Res Function(_Certificate) _then) = __$CertificateCopyWithImpl;
@override @useResult
$Res call({
 String id, String siteId, DateTime certificateDate, int periodYear, int periodMonth, int periodHalf, String amount, String? notes, CertificateStatus status, String? returnNote, String createdBy, DateTime? submittedAt, DateTime? lockedAt, DateTime? deletedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$CertificateCopyWithImpl<$Res>
    implements _$CertificateCopyWith<$Res> {
  __$CertificateCopyWithImpl(this._self, this._then);

  final _Certificate _self;
  final $Res Function(_Certificate) _then;

/// Create a copy of Certificate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? siteId = null,Object? certificateDate = null,Object? periodYear = null,Object? periodMonth = null,Object? periodHalf = null,Object? amount = null,Object? notes = freezed,Object? status = null,Object? returnNote = freezed,Object? createdBy = null,Object? submittedAt = freezed,Object? lockedAt = freezed,Object? deletedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Certificate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,siteId: null == siteId ? _self.siteId : siteId // ignore: cast_nullable_to_non_nullable
as String,certificateDate: null == certificateDate ? _self.certificateDate : certificateDate // ignore: cast_nullable_to_non_nullable
as DateTime,periodYear: null == periodYear ? _self.periodYear : periodYear // ignore: cast_nullable_to_non_nullable
as int,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as int,periodHalf: null == periodHalf ? _self.periodHalf : periodHalf // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CertificateStatus,returnNote: freezed == returnNote ? _self.returnNote : returnNote // ignore: cast_nullable_to_non_nullable
as String?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lockedAt: freezed == lockedAt ? _self.lockedAt : lockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
