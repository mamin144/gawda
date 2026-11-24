// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'site_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SiteRow {

 String get id; String get code; String get name;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'archived_at') DateTime? get archivedAt;
/// Create a copy of SiteRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SiteRowCopyWith<SiteRow> get copyWith => _$SiteRowCopyWithImpl<SiteRow>(this as SiteRow, _$identity);

  /// Serializes this SiteRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SiteRow;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SiteRow&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.code, _this.code) || other.code == _this.code)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.isActive, _this.isActive) || other.isActive == _this.isActive)&&(identical(other.archivedAt, _this.archivedAt) || other.archivedAt == _this.archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SiteRow;
  return Object.hash(runtimeType,_this.id,_this.code,_this.name,_this.isActive,_this.archivedAt);
}

@override
String toString() {
  final _this = this as SiteRow;
  return 'SiteRow(id: ${_this.id}, code: ${_this.code}, name: ${_this.name}, isActive: ${_this.isActive}, archivedAt: ${_this.archivedAt})';
}


}

/// @nodoc
abstract mixin class $SiteRowCopyWith<$Res>  {
  factory $SiteRowCopyWith(SiteRow value, $Res Function(SiteRow) _then) = _$SiteRowCopyWithImpl;
@useResult
$Res call({
 String id, String code, String name,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'archived_at') DateTime? archivedAt
});




}
/// @nodoc
class _$SiteRowCopyWithImpl<$Res>
    implements $SiteRowCopyWith<$Res> {
  _$SiteRowCopyWithImpl(this._self, this._then);

  final SiteRow _self;
  final $Res Function(SiteRow) _then;

/// Create a copy of SiteRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? isActive = null,Object? archivedAt = freezed,}) {
  return _then(SiteRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SiteRow].
extension SiteRowPatterns on SiteRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SiteRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SiteRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SiteRow value)  $default,){
final _that = this;
switch (_that) {
case _SiteRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SiteRow value)?  $default,){
final _that = this;
switch (_that) {
case _SiteRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String name, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'archived_at')  DateTime? archivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SiteRow() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.isActive,_that.archivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String name, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'archived_at')  DateTime? archivedAt)  $default,) {final _that = this;
switch (_that) {
case _SiteRow():
return $default(_that.id,_that.code,_that.name,_that.isActive,_that.archivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String name, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'archived_at')  DateTime? archivedAt)?  $default,) {final _that = this;
switch (_that) {
case _SiteRow() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.isActive,_that.archivedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SiteRow implements SiteRow {
  const _SiteRow({required this.id, required this.code, required this.name, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'archived_at') this.archivedAt});
  factory _SiteRow.fromJson(Map<String, dynamic> json) => _$SiteRowFromJson(json);

@override final  String id;
@override final  String code;
@override final  String name;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'archived_at') final  DateTime? archivedAt;

/// Create a copy of SiteRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SiteRowCopyWith<_SiteRow> get copyWith => __$SiteRowCopyWithImpl<_SiteRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SiteRowToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SiteRow&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,code,name,isActive,archivedAt);
}

@override
String toString() {
    return 'SiteRow(id: $id, code: $code, name: $name, isActive: $isActive, archivedAt: $archivedAt)';
}


}

/// @nodoc
abstract mixin class _$SiteRowCopyWith<$Res> implements $SiteRowCopyWith<$Res> {
  factory _$SiteRowCopyWith(_SiteRow value, $Res Function(_SiteRow) _then) = __$SiteRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String name,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'archived_at') DateTime? archivedAt
});




}
/// @nodoc
class __$SiteRowCopyWithImpl<$Res>
    implements _$SiteRowCopyWith<$Res> {
  __$SiteRowCopyWithImpl(this._self, this._then);

  final _SiteRow _self;
  final $Res Function(_SiteRow) _then;

/// Create a copy of SiteRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? isActive = null,Object? archivedAt = freezed,}) {
  return _then(_SiteRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
