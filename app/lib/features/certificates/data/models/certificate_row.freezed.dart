// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CertificateRow {

 String get id;@JsonKey(name: 'site_id') String get siteId;@JsonKey(name: 'certificate_date') DateTime get certificateDate;@JsonKey(name: 'period_year') int get periodYear;@JsonKey(name: 'period_month') int get periodMonth;@JsonKey(name: 'period_half') int get periodHalf; String get amount; String? get notes; String get status;@JsonKey(name: 'return_note') String? get returnNote;@JsonKey(name: 'created_by') String get createdBy;@JsonKey(name: 'submitted_at') DateTime? get submittedAt;@JsonKey(name: 'locked_at') DateTime? get lockedAt;@JsonKey(name: 'deleted_at') DateTime? get deletedAt;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'updated_at') DateTime get updatedAt;
/// Create a copy of CertificateRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateRowCopyWith<CertificateRow> get copyWith => _$CertificateRowCopyWithImpl<CertificateRow>(this as CertificateRow, _$identity);

  /// Serializes this CertificateRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CertificateRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.siteId, _this.siteId) || other.siteId == _this.siteId)&&(identical(other.certificateDate, _this.certificateDate) || other.certificateDate == _this.certificateDate)&&(identical(other.periodYear, _this.periodYear) || other.periodYear == _this.periodYear)&&(identical(other.periodMonth, _this.periodMonth) || other.periodMonth == _this.periodMonth)&&(identical(other.periodHalf, _this.periodHalf) || other.periodHalf == _this.periodHalf)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.returnNote, _this.returnNote) || other.returnNote == _this.returnNote)&&(identical(other.createdBy, _this.createdBy) || other.createdBy == _this.createdBy)&&(identical(other.submittedAt, _this.submittedAt) || other.submittedAt == _this.submittedAt)&&(identical(other.lockedAt, _this.lockedAt) || other.lockedAt == _this.lockedAt)&&(identical(other.deletedAt, _this.deletedAt) || other.deletedAt == _this.deletedAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CertificateRow;
  return Object.hash(runtimeType,_this.id,_this.siteId,_this.certificateDate,_this.periodYear,_this.periodMonth,_this.periodHalf,_this.amount,_this.notes,_this.status,_this.returnNote,_this.createdBy,_this.submittedAt,_this.lockedAt,_this.deletedAt,_this.createdAt,_this.updatedAt);
}

@override
String toString() {
  final _this = this as CertificateRow;
  return 'CertificateRow(id: ${_this.id}, siteId: ${_this.siteId}, certificateDate: ${_this.certificateDate}, periodYear: ${_this.periodYear}, periodMonth: ${_this.periodMonth}, periodHalf: ${_this.periodHalf}, amount: ${_this.amount}, notes: ${_this.notes}, status: ${_this.status}, returnNote: ${_this.returnNote}, createdBy: ${_this.createdBy}, submittedAt: ${_this.submittedAt}, lockedAt: ${_this.lockedAt}, deletedAt: ${_this.deletedAt}, createdAt: ${_this.createdAt}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $CertificateRowCopyWith<$Res>  {
  factory $CertificateRowCopyWith(CertificateRow value, $Res Function(CertificateRow) _then) = _$CertificateRowCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'site_id') String siteId,@JsonKey(name: 'certificate_date') DateTime certificateDate,@JsonKey(name: 'period_year') int periodYear,@JsonKey(name: 'period_month') int periodMonth,@JsonKey(name: 'period_half') int periodHalf, String amount, String? notes, String status,@JsonKey(name: 'return_note') String? returnNote,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'submitted_at') DateTime? submittedAt,@JsonKey(name: 'locked_at') DateTime? lockedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class _$CertificateRowCopyWithImpl<$Res>
    implements $CertificateRowCopyWith<$Res> {
  _$CertificateRowCopyWithImpl(this._self, this._then);

  final CertificateRow _self;
  final $Res Function(CertificateRow) _then;

/// Create a copy of CertificateRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? siteId = null,Object? certificateDate = null,Object? periodYear = null,Object? periodMonth = null,Object? periodHalf = null,Object? amount = null,Object? notes = freezed,Object? status = null,Object? returnNote = freezed,Object? createdBy = null,Object? submittedAt = freezed,Object? lockedAt = freezed,Object? deletedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(CertificateRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,siteId: null == siteId ? _self.siteId : siteId // ignore: cast_nullable_to_non_nullable
as String,certificateDate: null == certificateDate ? _self.certificateDate : certificateDate // ignore: cast_nullable_to_non_nullable
as DateTime,periodYear: null == periodYear ? _self.periodYear : periodYear // ignore: cast_nullable_to_non_nullable
as int,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as int,periodHalf: null == periodHalf ? _self.periodHalf : periodHalf // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,returnNote: freezed == returnNote ? _self.returnNote : returnNote // ignore: cast_nullable_to_non_nullable
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


/// Adds pattern-matching-related methods to [CertificateRow].
extension CertificateRowPatterns on CertificateRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateRow value)  $default,){
final _that = this;
switch (_that) {
case _CertificateRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateRow value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'site_id')  String siteId, @JsonKey(name: 'certificate_date')  DateTime certificateDate, @JsonKey(name: 'period_year')  int periodYear, @JsonKey(name: 'period_month')  int periodMonth, @JsonKey(name: 'period_half')  int periodHalf,  String amount,  String? notes,  String status, @JsonKey(name: 'return_note')  String? returnNote, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'submitted_at')  DateTime? submittedAt, @JsonKey(name: 'locked_at')  DateTime? lockedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateRow() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'site_id')  String siteId, @JsonKey(name: 'certificate_date')  DateTime certificateDate, @JsonKey(name: 'period_year')  int periodYear, @JsonKey(name: 'period_month')  int periodMonth, @JsonKey(name: 'period_half')  int periodHalf,  String amount,  String? notes,  String status, @JsonKey(name: 'return_note')  String? returnNote, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'submitted_at')  DateTime? submittedAt, @JsonKey(name: 'locked_at')  DateTime? lockedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _CertificateRow():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'site_id')  String siteId, @JsonKey(name: 'certificate_date')  DateTime certificateDate, @JsonKey(name: 'period_year')  int periodYear, @JsonKey(name: 'period_month')  int periodMonth, @JsonKey(name: 'period_half')  int periodHalf,  String amount,  String? notes,  String status, @JsonKey(name: 'return_note')  String? returnNote, @JsonKey(name: 'created_by')  String createdBy, @JsonKey(name: 'submitted_at')  DateTime? submittedAt, @JsonKey(name: 'locked_at')  DateTime? lockedAt, @JsonKey(name: 'deleted_at')  DateTime? deletedAt, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'updated_at')  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _CertificateRow() when $default != null:
return $default(_that.id,_that.siteId,_that.certificateDate,_that.periodYear,_that.periodMonth,_that.periodHalf,_that.amount,_that.notes,_that.status,_that.returnNote,_that.createdBy,_that.submittedAt,_that.lockedAt,_that.deletedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CertificateRow implements CertificateRow {
  const _CertificateRow({required this.id, @JsonKey(name: 'site_id') required this.siteId, @JsonKey(name: 'certificate_date') required this.certificateDate, @JsonKey(name: 'period_year') required this.periodYear, @JsonKey(name: 'period_month') required this.periodMonth, @JsonKey(name: 'period_half') required this.periodHalf, required this.amount, this.notes, required this.status, @JsonKey(name: 'return_note') this.returnNote, @JsonKey(name: 'created_by') required this.createdBy, @JsonKey(name: 'submitted_at') this.submittedAt, @JsonKey(name: 'locked_at') this.lockedAt, @JsonKey(name: 'deleted_at') this.deletedAt, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt});
  factory _CertificateRow.fromJson(Map<String, dynamic> json) => _$CertificateRowFromJson(json);

@override final  String id;
@override@JsonKey(name: 'site_id') final  String siteId;
@override@JsonKey(name: 'certificate_date') final  DateTime certificateDate;
@override@JsonKey(name: 'period_year') final  int periodYear;
@override@JsonKey(name: 'period_month') final  int periodMonth;
@override@JsonKey(name: 'period_half') final  int periodHalf;
@override final  String amount;
@override final  String? notes;
@override final  String status;
@override@JsonKey(name: 'return_note') final  String? returnNote;
@override@JsonKey(name: 'created_by') final  String createdBy;
@override@JsonKey(name: 'submitted_at') final  DateTime? submittedAt;
@override@JsonKey(name: 'locked_at') final  DateTime? lockedAt;
@override@JsonKey(name: 'deleted_at') final  DateTime? deletedAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;

/// Create a copy of CertificateRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateRowCopyWith<_CertificateRow> get copyWith => __$CertificateRowCopyWithImpl<_CertificateRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CertificateRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateRow&&(identical(other.id, id) || other.id == id)&&(identical(other.siteId, siteId) || other.siteId == siteId)&&(identical(other.certificateDate, certificateDate) || other.certificateDate == certificateDate)&&(identical(other.periodYear, periodYear) || other.periodYear == periodYear)&&(identical(other.periodMonth, periodMonth) || other.periodMonth == periodMonth)&&(identical(other.periodHalf, periodHalf) || other.periodHalf == periodHalf)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.status, status) || other.status == status)&&(identical(other.returnNote, returnNote) || other.returnNote == returnNote)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.lockedAt, lockedAt) || other.lockedAt == lockedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,siteId,certificateDate,periodYear,periodMonth,periodHalf,amount,notes,status,returnNote,createdBy,submittedAt,lockedAt,deletedAt,createdAt,updatedAt);
}

@override
String toString() {
    return 'CertificateRow(id: $id, siteId: $siteId, certificateDate: $certificateDate, periodYear: $periodYear, periodMonth: $periodMonth, periodHalf: $periodHalf, amount: $amount, notes: $notes, status: $status, returnNote: $returnNote, createdBy: $createdBy, submittedAt: $submittedAt, lockedAt: $lockedAt, deletedAt: $deletedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$CertificateRowCopyWith<$Res> implements $CertificateRowCopyWith<$Res> {
  factory _$CertificateRowCopyWith(_CertificateRow value, $Res Function(_CertificateRow) _then) = __$CertificateRowCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'site_id') String siteId,@JsonKey(name: 'certificate_date') DateTime certificateDate,@JsonKey(name: 'period_year') int periodYear,@JsonKey(name: 'period_month') int periodMonth,@JsonKey(name: 'period_half') int periodHalf, String amount, String? notes, String status,@JsonKey(name: 'return_note') String? returnNote,@JsonKey(name: 'created_by') String createdBy,@JsonKey(name: 'submitted_at') DateTime? submittedAt,@JsonKey(name: 'locked_at') DateTime? lockedAt,@JsonKey(name: 'deleted_at') DateTime? deletedAt,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'updated_at') DateTime updatedAt
});




}
/// @nodoc
class __$CertificateRowCopyWithImpl<$Res>
    implements _$CertificateRowCopyWith<$Res> {
  __$CertificateRowCopyWithImpl(this._self, this._then);

  final _CertificateRow _self;
  final $Res Function(_CertificateRow) _then;

/// Create a copy of CertificateRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? siteId = null,Object? certificateDate = null,Object? periodYear = null,Object? periodMonth = null,Object? periodHalf = null,Object? amount = null,Object? notes = freezed,Object? status = null,Object? returnNote = freezed,Object? createdBy = null,Object? submittedAt = freezed,Object? lockedAt = freezed,Object? deletedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_CertificateRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,siteId: null == siteId ? _self.siteId : siteId // ignore: cast_nullable_to_non_nullable
as String,certificateDate: null == certificateDate ? _self.certificateDate : certificateDate // ignore: cast_nullable_to_non_nullable
as DateTime,periodYear: null == periodYear ? _self.periodYear : periodYear // ignore: cast_nullable_to_non_nullable
as int,periodMonth: null == periodMonth ? _self.periodMonth : periodMonth // ignore: cast_nullable_to_non_nullable
as int,periodHalf: null == periodHalf ? _self.periodHalf : periodHalf // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,returnNote: freezed == returnNote ? _self.returnNote : returnNote // ignore: cast_nullable_to_non_nullable
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
