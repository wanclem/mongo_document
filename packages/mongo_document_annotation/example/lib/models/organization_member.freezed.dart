// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'organization_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrganizationMember {

@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? get id;@JsonKey(name: 'user_id') User? get user; Organization? get organization; String? get occupation; String? get role; String? get title;@DateTimeConverter() DateTime? get createdAt;@DateTimeConverter() DateTime? get updatedAt;
/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrganizationMemberCopyWith<OrganizationMember> get copyWith => _$OrganizationMemberCopyWithImpl<OrganizationMember>(this as OrganizationMember, _$identity);

  /// Serializes this OrganizationMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrganizationMember&&(identical(other.id, id) || other.id == id)&&(identical(other.user, user) || other.user == user)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.role, role) || other.role == role)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,user,organization,occupation,role,title,createdAt,updatedAt);

@override
String toString() {
  return 'OrganizationMember(id: $id, user: $user, organization: $organization, occupation: $occupation, role: $role, title: $title, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $OrganizationMemberCopyWith<$Res>  {
  factory $OrganizationMemberCopyWith(OrganizationMember value, $Res Function(OrganizationMember) _then) = _$OrganizationMemberCopyWithImpl;
@useResult
$Res call({
@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? id,@JsonKey(name: 'user_id') User? user, Organization? organization, String? occupation, String? role, String? title,@DateTimeConverter() DateTime? createdAt,@DateTimeConverter() DateTime? updatedAt
});


$UserCopyWith<$Res>? get user;$OrganizationCopyWith<$Res>? get organization;

}
/// @nodoc
class _$OrganizationMemberCopyWithImpl<$Res>
    implements $OrganizationMemberCopyWith<$Res> {
  _$OrganizationMemberCopyWithImpl(this._self, this._then);

  final OrganizationMember _self;
  final $Res Function(OrganizationMember) _then;

/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? user = freezed,Object? organization = freezed,Object? occupation = freezed,Object? role = freezed,Object? title = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ObjectId?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get organization {
    if (_self.organization == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.organization!, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}


/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _OrganizationMember implements OrganizationMember {
  const _OrganizationMember({@ObjectIdConverter()@JsonKey(name: '_id') this.id, @JsonKey(name: 'user_id') this.user, this.organization, this.occupation, this.role, this.title, @DateTimeConverter() this.createdAt, @DateTimeConverter() this.updatedAt});
  factory _OrganizationMember.fromJson(Map<String, dynamic> json) => _$OrganizationMemberFromJson(json);

@override@ObjectIdConverter()@JsonKey(name: '_id') final  ObjectId? id;
@override@JsonKey(name: 'user_id') final  User? user;
@override final  Organization? organization;
@override final  String? occupation;
@override final  String? role;
@override final  String? title;
@override@DateTimeConverter() final  DateTime? createdAt;
@override@DateTimeConverter() final  DateTime? updatedAt;

/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrganizationMemberCopyWith<_OrganizationMember> get copyWith => __$OrganizationMemberCopyWithImpl<_OrganizationMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrganizationMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrganizationMember&&(identical(other.id, id) || other.id == id)&&(identical(other.user, user) || other.user == user)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.occupation, occupation) || other.occupation == occupation)&&(identical(other.role, role) || other.role == role)&&(identical(other.title, title) || other.title == title)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,user,organization,occupation,role,title,createdAt,updatedAt);

@override
String toString() {
  return 'OrganizationMember(id: $id, user: $user, organization: $organization, occupation: $occupation, role: $role, title: $title, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$OrganizationMemberCopyWith<$Res> implements $OrganizationMemberCopyWith<$Res> {
  factory _$OrganizationMemberCopyWith(_OrganizationMember value, $Res Function(_OrganizationMember) _then) = __$OrganizationMemberCopyWithImpl;
@override @useResult
$Res call({
@ObjectIdConverter()@JsonKey(name: '_id') ObjectId? id,@JsonKey(name: 'user_id') User? user, Organization? organization, String? occupation, String? role, String? title,@DateTimeConverter() DateTime? createdAt,@DateTimeConverter() DateTime? updatedAt
});


@override $UserCopyWith<$Res>? get user;@override $OrganizationCopyWith<$Res>? get organization;

}
/// @nodoc
class __$OrganizationMemberCopyWithImpl<$Res>
    implements _$OrganizationMemberCopyWith<$Res> {
  __$OrganizationMemberCopyWithImpl(this._self, this._then);

  final _OrganizationMember _self;
  final $Res Function(_OrganizationMember) _then;

/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? user = freezed,Object? organization = freezed,Object? occupation = freezed,Object? role = freezed,Object? title = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_OrganizationMember(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ObjectId?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as Organization?,occupation: freezed == occupation ? _self.occupation : occupation // ignore: cast_nullable_to_non_nullable
as String?,role: freezed == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of OrganizationMember
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrganizationCopyWith<$Res>? get organization {
    if (_self.organization == null) {
    return null;
  }

  return $OrganizationCopyWith<$Res>(_self.organization!, (value) {
    return _then(_self.copyWith(organization: value));
  });
}
}

// dart format on
