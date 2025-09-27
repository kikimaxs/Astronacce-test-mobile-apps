import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';
import 'bloc/user_bloc.dart';
import 'bloc/user_event.dart';
import 'repositories/user_repository.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'screens/user_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/direct_password_reset_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/add_user_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(authService: AuthService())
            ..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (context) => UserBloc(userRepository: UserRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'Astronacce App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
          '/direct-password-reset': (context) => DirectPasswordResetScreen(),
          '/user-list': (context) => UserListScreen(),
          '/add-user': (context) => AddUserScreen(),
          '/edit-profile': (context) => EditProfileScreen(
            user: ModalRoute.of(context)!.settings.arguments as User,
          ),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Reset UserBloc ketika user logout
        if (state is AuthUnauthenticated) {
          context.read<UserBloc>().add(ResetUsers());
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is AuthAuthenticated) {
            return UserListScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
