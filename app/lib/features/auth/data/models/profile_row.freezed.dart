// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfileRow {

 String get id;@JsonKey(name: 'full_name') String get fullName; String get role;@JsonKey(name: 'is_active') bool get isActive;
/// Create a copy of ProfileRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileRowCopyWith<ProfileRow> get copyWith => _$ProfileRowCopyWithImpl<ProfileRow>(this as ProfileRow, _$identity);

  /// Serializes this ProfileRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProfileRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfileRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProfileRow;
  return Object.hash(runtimeType,_this.id,_this.fullName,_this.role,_this.isActive);
}

@override
String toString() {
  final _this = this as ProfileRow;
  return 'ProfileRow(id: ${_this.id}, fullName: ${_this.fullName}, role: ${_this.role}, isActive: ${_this.isActive})';
}


}

/// @nodoc
abstract mixin class $ProfileRowCopyWith<$Res>  {
  factory $ProfileRowCopyWith(ProfileRow value, $Res Function(ProfileRow) _then) = _$ProfileRowCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName, String role,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class _$ProfileRowCopyWithImpl<$Res>
    implements $ProfileRowCopyWith<$Res> {
  _$ProfileRowCopyWithImpl(this._self, this._then);

  final ProfileRow _self;
  final $Res Function(ProfileRow) _then;

/// Create a copy of ProfileRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? role = null,Object? isActive = null,}) {
  return _then(ProfileRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfileRow].
extension ProfileRowPatterns on ProfileRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfileRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfileRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfileRow value)  $default,){
final _that = this;
switch (_that) {
case _ProfileRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfileRow value)?  $default,){
final _that = this;
switch (_that) {
case _ProfileRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName,  String role, @JsonKey(name: 'is_active')  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfileRow() when $default != null:
return $default(_that.id,_that.fullName,_that.role,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'full_name')  String fullName,  String role, @JsonKey(name: 'is_active')  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _ProfileRow():
return $default(_that.id,_that.fullName,_that.role,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'full_name')  String fullName,  String role, @JsonKey(name: 'is_active')  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _ProfileRow() when $default != null:
return $default(_that.id,_that.fullName,_that.role,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfileRow implements ProfileRow {
  const _ProfileRow({required this.id, @JsonKey(name: 'full_name') required this.fullName, required this.role, @JsonKey(name: 'is_active') required this.isActive});
  factory _ProfileRow.fromJson(Map<String, dynamic> json) => _$ProfileRowFromJson(json);

@override final  String id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  String role;
@override@JsonKey(name: 'is_active') final  bool isActive;

/// Create a copy of ProfileRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfileRowCopyWith<_ProfileRow> get copyWith => __$ProfileRowCopyWithImpl<_ProfileRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfileRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfileRow&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.role, role) || other.role == role)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fullName,role,isActive);
}

@override
String toString() {
    return 'ProfileRow(id: $id, fullName: $fullName, role: $role, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$ProfileRowCopyWith<$Res> implements $ProfileRowCopyWith<$Res> {
  factory _$ProfileRowCopyWith(_ProfileRow value, $Res Function(_ProfileRow) _then) = __$ProfileRowCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'full_name') String fullName, String role,@JsonKey(name: 'is_active') bool isActive
});




}
/// @nodoc
class __$ProfileRowCopyWithImpl<$Res>
    implements _$ProfileRowCopyWith<$Res> {
  __$ProfileRowCopyWithImpl(this._self, this._then);

  final _ProfileRow _self;
  final $Res Function(_ProfileRow) _then;

/// Create a copy of ProfileRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? role = null,Object? isActive = null,}) {
  return _then(_ProfileRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
