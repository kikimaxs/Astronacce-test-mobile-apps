// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
      'phone': instance.phone,
      'address': instance.address,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'user': instance.user,
      'token': instance.token,
    };

UsersResponse _$UsersResponseFromJson(Map<String, dynamic> json) =>
    UsersResponse(
      users: (json['users'] as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UsersResponseToJson(UsersResponse instance) =>
    <String, dynamic>{
      'users': instance.users,
      'pagination': instance.pagination,
    };

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
      currentPage: (json['currentPage'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      totalUsers: (json['totalUsers'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );

Map<String, dynamic> _$PaginationToJson(Pagination instance) =>
    <String, dynamic>{
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'totalUsers': instance.totalUsers,
      'hasNext': instance.hasNext,
      'hasPrev': instance.hasPrev,
    };
