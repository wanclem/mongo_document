// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Organization {

@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? get id; String? get tempId; User? get owner; String? get name; dynamic get avatar; Map<String, dynamic> get ephemeralData; bool get active;@DateTimeConverter() DateTime? get createdAt;@DateTimeConverter() DateTime? get updatedAt;
/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationCopyWith<Organization> get copyWith => _$OrganizationCopyWithImpl<Organization>(this as Organization, _$identity);

  /// Serializes this Organization to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Organization&&(identical(other.id, id) || other.id == id)&&(identical(other.tempId, tempId) || other.tempId == tempId)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.avatar, avatar)&&const DeepCollectionEquality().equals(other.ephemeralData, ephemeralData)&&(identical(other.active, active) || other.active == active)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tempId,owner,name,const DeepCollectionEquality().hash(avatar),const DeepCollectionEquality().hash(ephemeralData),active,createdAt,updatedAt);

@override
String toString() {
  return 'Organization(id: $id, tempId: $tempId, owner: $owner, name: $name, avatar: $avatar, ephemeralData: $ephemeralData, active: $active, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $OrganizationCopyWith<$Res>  {
  factory $OrganizationCopyWith(Organization value, $Res Function(Organization) _then) = _$OrganizationCopyWithImpl;
@useResult
$Res call({
@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? id, String? tempId, User? owner, String? name, dynamic avatar, Map<String, dynamic> ephemeralData, bool active,@DateTimeConverter() DateTime? createdAt,@DateTimeConverter() DateTime? updatedAt
});


$UserCopyWith<$Res>? get owner;

}
/// @nodoc
class _$OrganizationCopyWithImpl<$Res>
    implements $OrganizationCopyWith<$Res> {
  _$OrganizationCopyWithImpl(this._self, this._then);

  final Organization _self;
  final $Res Function(Organization) _then;

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? tempId = freezed,Object? owner = freezed,Object? name = freezed,Object? avatar = freezed,Object? ephemeralData = null,Object? active = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ObjectId?,tempId: freezed == tempId ? _self.tempId : tempId // ignore: cast_nullable_to_non_nullable
as String?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as User?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as dynamic,ephemeralData: null == ephemeralData ? _self.ephemeralData : ephemeralData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _Organization implements Organization {
  const _Organization({@ObjectIdConverter()@JsonKey(name: '_id') this.id, this.tempId, this.owner, this.name, this.avatar, final  Map<String, dynamic> ephemeralData = const {}, this.active = false, @DateTimeConverter() this.createdAt, @DateTimeConverter() this.updatedAt}): _ephemeralData = ephemeralData;
  factory _Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);

@override@ObjectIdConverter()@JsonKey(name: '_id') final  ObjectId? id;
@override final  String? tempId;
@override final  User? owner;
@override final  String? name;
@override final  dynamic avatar;
 final  Map<String, dynamic> _ephemeralData;
@override@JsonKey() Map<String, dynamic> get ephemeralData {
  if (_ephemeralData is EqualUnmodifiableMapView) return _ephemeralData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_ephemeralData);
}

@override@JsonKey() final  bool active;
@override@DateTimeConverter() final  DateTime? createdAt;
@override@DateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationCopyWith<_Organization> get copyWith => __$OrganizationCopyWithImpl<_Organization>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Organization&&(identical(other.id, id) || other.id == id)&&(identical(other.tempId, tempId) || other.tempId == tempId)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.avatar, avatar)&&const DeepCollectionEquality().equals(other._ephemeralData, _ephemeralData)&&(identical(other.active, active) || other.active == active)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tempId,owner,name,const DeepCollectionEquality().hash(avatar),const DeepCollectionEquality().hash(_ephemeralData),active,createdAt,updatedAt);

@override
String toString() {
  return 'Organization(id: $id, tempId: $tempId, owner: $owner, name: $name, avatar: $avatar, ephemeralData: $ephemeralData, active: $active, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$OrganizationCopyWith<$Res> implements $OrganizationCopyWith<$Res> {
  factory _$OrganizationCopyWith(_Organization value, $Res Function(_Organization) _then) = __$OrganizationCopyWithImpl;
@override @useResult
$Res call({
@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? id, String? tempId, User? owner, String? name, dynamic avatar, Map<String, dynamic> ephemeralData, bool active,@DateTimeConverter() DateTime? createdAt,@DateTimeConverter() DateTime? updatedAt
});


@override $UserCopyWith<$Res>? get owner;

}
/// @nodoc
class __$OrganizationCopyWithImpl<$Res>
    implements _$OrganizationCopyWith<$Res> {
  __$OrganizationCopyWithImpl(this._self, this._then);

  final _Organization _self;
  final $Res Function(_Organization) _then;

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? tempId = freezed,Object? owner = freezed,Object? name = freezed,Object? avatar = freezed,Object? ephemeralData = null,Object? active = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Organization(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ObjectId?,tempId: freezed == tempId ? _self.tempId : tempId // ignore: cast_nullable_to_non_nullable
as String?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as User?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as dynamic,ephemeralData: null == ephemeralData ? _self._ephemeralData : ephemeralData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Organization
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

// dart format on
