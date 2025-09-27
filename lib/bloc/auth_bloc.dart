import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthResetPasswordRequested>(_onAuthResetPasswordRequested);
    on<AuthDirectPasswordResetRequested>(_onAuthDirectPasswordResetRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isLoggedIn = await authService.isLoggedIn();
      if (isLoggedIn) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authService.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authService.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await authService.forgotPassword(email: event.email);
      
      // Create message with reset token if available (development mode)
      String message = result['message'] ?? 'Reset instructions sent to your email';
      if (result['resetToken'] != null) {
        message += '\n\nReset token: ${result['resetToken']}';
        if (result['expiresAt'] != null) {
          message += '\nExpires: ${result['expiresAt']}';
        }
      }
      
      emit(AuthForgotPasswordSuccess(
        message: message,
        resetToken: result['resetToken'],
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await authService.resetPassword(
        token: event.token,
        newPassword: event.newPassword,
      );
      
      emit(AuthResetPasswordSuccess(
        message: result['message'] ?? 'Password reset successful',
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // Tambahkan handler baru untuk direct password reset
  Future<void> _onAuthDirectPasswordResetRequested(
    AuthDirectPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await authService.directPasswordReset(
        email: event.email,
        newPassword: event.newPassword,
      );
      
      emit(AuthDirectPasswordResetSuccess(
        message: result['message'] ?? 'Password berhasil diubah',
        user: result['user'],
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authService.updateProfile(
        name: event.name ?? '',
        phone: event.phone,
        address: event.address,
        avatar: event.avatar,
      );
      
      emit(AuthProfileUpdateSuccess(
        message: 'Profile berhasil diperbarui',
        user: user,
      ));
      
      // Emit authenticated state with updated user
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}