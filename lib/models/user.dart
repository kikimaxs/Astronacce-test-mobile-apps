import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? phone;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.phone,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseId(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static int _parseId(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, email, avatar, phone, address, createdAt, updatedAt];
}

class AuthResponse extends Equatable {
  final User user;
  final String token;

  const AuthResponse({
    required this.user,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }

  @override
  List<Object> get props => [user, token];
}

class UsersResponse extends Equatable {
  final List<User> users;
  final Pagination pagination;

  const UsersResponse({
    required this.users,
    required this.pagination,
  });

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    return UsersResponse(
      users: (json['users'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((user) => user.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  @override
  List<Object> get props => [users, pagination];
}

class Pagination extends Equatable {
  final int currentPage;
  final int totalPages;
  final int totalUsers;
  final bool hasNext;
  final bool hasPrev;

  const Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalUsers,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: _parseInt(json['currentPage']) ?? 1,
      totalPages: _parseInt(json['totalPages']) ?? 1,
      totalUsers: _parseInt(json['totalUsers']) ?? 0,
      hasNext: json['hasNext'] == true,
      hasPrev: json['hasPrev'] == true,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalUsers': totalUsers,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }

  @override
  List<Object> get props => [currentPage, totalPages, totalUsers, hasNext, hasPrev];
}