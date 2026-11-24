// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'managed_user_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ManagedUserRow {

 String get id; String get email;@JsonKey(name: 'full_name') String get fullName; String get role;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'invite_pending') bool get invitePending;@JsonKey(name: 'site_ids') List<String>? get siteIds;
/// Create a copy of ManagedUserRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManagedUserRowCopyWith<ManagedUserRow> get copyWith => _$ManagedUserRowCopyWithImpl<ManagedUserRow>(this as ManagedUserRow, _$identity);

  /// Serializes this ManagedUserRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ManagedUserRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManagedUserRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.invitePending, _this.invitePending) || other.invitePending == _this.invitePending)&&const DeepCollectionEquality().equals(other.siteIds, _this.siteIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ManagedUserRow;
  return Object.hash(runtimeType,_this.id,_this.email,_this.fullName,_this.role,_this.isActive,_this.invitePending,const DeepCollectionEquality().hash(_this.siteIds));
}

@override
String toString() {
  final _this = this as ManagedUserRow;
  return 'ManagedUserRow(id: ${_this.id}, email: ${_this.email}, fullName: ${_this.fullName}, role: ${_this.role}, isActive: ${_this.isActive}, invitePending: ${_this.invitePending}, siteIds: ${_this.siteIds})';
}


}

/// @nodoc
abstract mixin class $ManagedUserRowCopyWith<$Res>  {
  factory $ManagedUserRowCopyWith(ManagedUserRow value, $Res Function(ManagedUserRow) _then) = _$ManagedUserRowCopyWithImpl;
@useResult
$Res call({
 String id, String email,@JsonKey(name: 'full_name') String fullName, String role,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'invite_pending') bool invitePending,@JsonKey(name: 'site_ids') List<String>? siteIds
});




}
/// @nodoc
class _$ManagedUserRowCopyWithImpl<$Res>
    implements $ManagedUserRowCopyWith<$Res> {
  _$ManagedUserRowCopyWithImpl(this._self, this._then);

  final ManagedUserRow _self;
  final $Res Function(ManagedUserRow) _then;

/// Create a copy of ManagedUserRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? fullName = null,Object? role = null,Object? isActive = null,Object? invitePending = null,Object? siteIds = freezed,}) {
  return _then(ManagedUserRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,invitePending: null == invitePending ? _self.invitePending : invitePending // ignore: cast_nullable_to_non_nullable
as bool,siteIds: freezed == siteIds ? _self.siteIds : siteIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ManagedUserRow].
extension ManagedUserRowPatterns on ManagedUserRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ManagedUserRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ManagedUserRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ManagedUserRow value)  $default,){
final _that = this;
switch (_that) {
case _ManagedUserRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ManagedUserRow value)?  $default,){
final _that = this;
switch (_that) {
case _ManagedUserRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String email, @JsonKey(name: 'full_name')  String fullName,  String role, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'invite_pending')  bool invitePending, @JsonKey(name: 'site_ids')  List<String>? siteIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ManagedUserRow() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.role,_that.isActive,_that.invitePending,_that.siteIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String email, @JsonKey(name: 'full_name')  String fullName,  String role, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'invite_pending')  bool invitePending, @JsonKey(name: 'site_ids')  List<String>? siteIds)  $default,) {final _that = this;
switch (_that) {
case _ManagedUserRow():
return $default(_that.id,_that.email,_that.fullName,_that.role,_that.isActive,_that.invitePending,_that.siteIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String email, @JsonKey(name: 'full_name')  String fullName,  String role, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'invite_pending')  bool invitePending, @JsonKey(name: 'site_ids')  List<String>? siteIds)?  $default,) {final _that = this;
switch (_that) {
case _ManagedUserRow() when $default != null:
return $default(_that.id,_that.email,_that.fullName,_that.role,_that.isActive,_that.invitePending,_that.siteIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ManagedUserRow implements ManagedUserRow {
  const _ManagedUserRow({required this.id, required this.email, @JsonKey(name: 'full_name') required this.fullName, required this.role, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'invite_pending') required this.invitePending, @JsonKey(name: 'site_ids')  List<String>? siteIds}): _siteIds = siteIds;
  factory _ManagedUserRow.fromJson(Map<String, dynamic> json) => _$ManagedUserRowFromJson(json);

@override final  String id;
@override final  String email;
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  String role;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'invite_pending') final  bool invitePending;
 final  List<String>? _siteIds;
@override@JsonKey(name: 'site_ids') List<String>? get siteIds {
  final value = _siteIds;
  if (value == null) return null;
  if (_siteIds is EqualUnmodifiableListView) return _siteIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ManagedUserRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManagedUserRowCopyWith<_ManagedUserRow> get copyWith => __$ManagedUserRowCopyWithImpl<_ManagedUserRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ManagedUserRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManagedUserRow&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.invitePending, invitePending) || other.invitePending == invitePending)&&const DeepCollectionEquality().equals(other.siteIds, _siteIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,email,fullName,role,isActive,invitePending,const DeepCollectionEquality().hash(_siteIds));
}

@override
String toString() {
    return 'ManagedUserRow(id: $id, email: $email, fullName: $fullName, role: $role, isActive: $isActive, invitePending: $invitePending, siteIds: $siteIds)';
}


}

/// @nodoc
abstract mixin class _$ManagedUserRowCopyWith<$Res> implements $ManagedUserRowCopyWith<$Res> {
  factory _$ManagedUserRowCopyWith(_ManagedUserRow value, $Res Function(_ManagedUserRow) _then) = __$ManagedUserRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String email,@JsonKey(name: 'full_name') String fullName, String role,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'invite_pending') bool invitePending,@JsonKey(name: 'site_ids') List<String>? siteIds
});




}
/// @nodoc
class __$ManagedUserRowCopyWithImpl<$Res>
    implements _$ManagedUserRowCopyWith<$Res> {
  __$ManagedUserRowCopyWithImpl(this._self, this._then);

  final _ManagedUserRow _self;
  final $Res Function(_ManagedUserRow) _then;

/// Create a copy of ManagedUserRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? fullName = null,Object? role = null,Object? isActive = null,Object? invitePending = null,Object? siteIds = freezed,}) {
  return _then(_ManagedUserRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,invitePending: null == invitePending ? _self.invitePending : invitePending // ignore: cast_nullable_to_non_nullable
as bool,siteIds: freezed == siteIds ? _self._siteIds : siteIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
