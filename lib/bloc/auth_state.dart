import 'package:equatable/equatable.dart';
import '../models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthForgotPasswordSuccess extends AuthState {
  final String message;
  final String? resetToken;

  const AuthForgotPasswordSuccess({
    required this.message,
    this.resetToken,
  });

  @override
  List<Object?> get props => [message, resetToken];
}

class AuthResetPasswordSuccess extends AuthState {
  final String message;

  const AuthResetPasswordSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthDirectPasswordResetSuccess extends AuthState {
  final String message;
  final Map<String, dynamic>? user;

  const AuthDirectPasswordResetSuccess({
    required this.message,
    this.user,
  });

  @override
  List<Object?> get props => [message, user];
}

class AuthProfileUpdateSuccess extends AuthState {
  final String message;
  final User user;

  const AuthProfileUpdateSuccess({
    required this.message,
    required this.user,
  });

  @override
  List<Object> get props => [message, user];
}

class AuthRegisterSuccess extends AuthState {
  final String message;

  const AuthRegisterSuccess({required this.message});

  @override
  List<Object> get props => [message];
}
