import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [name, email, password];
}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object> get props => [email];
}

class AuthResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const AuthResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object> get props => [token, newPassword];
}

// Tambahkan event baru untuk direct password reset
class AuthDirectPasswordResetRequested extends AuthEvent {
  final String email;
  final String newPassword;

  const AuthDirectPasswordResetRequested({
    required this.email,
    required this.newPassword,
  });

  @override
  List<Object> get props => [email, newPassword];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? name;
  final String? phone;
  final String? address;
  final String? avatar;

  const AuthProfileUpdateRequested({
    this.name,
    this.phone,
    this.address,
    this.avatar,
  });

  @override
  List<Object?> get props => [name, phone, address, avatar];
}