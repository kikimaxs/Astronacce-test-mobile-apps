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
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Reset cache untuk menggunakan URL baru
  print('🔄 Resetting API cache for new endpoint...');
  ApiConfig.resetCache();
  
  // Inisialisasi endpoint saat aplikasi dimulai
  print('🚀 Initializing API endpoint...');
  try {
    final endpoint = await ApiConfig.baseUrl;
    print('✅ API endpoint initialized: $endpoint');
  } catch (e) {
    print('⚠️ Failed to initialize API endpoint: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        title: 'Astronacce Test Mobile Apps',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (state is AuthAuthenticated) {
              // Load users when authenticated
              context.read<UserBloc>().add(LoadUsers());
              return UserListScreen();
            } else {
              return LoginScreen();
            }
          },
        ),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/forgot-password': (context) => ForgotPasswordScreen(),
          '/direct-password-reset': (context) => DirectPasswordResetScreen(),
          '/users': (context) => UserListScreen(),
          '/add-user': (context) => AddUserScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/edit-profile') {
            final user = settings.arguments as User;
            return MaterialPageRoute(
              builder: (context) => EditProfileScreen(user: user),
            );
          }
          return null;
        },
      ),
    );
  }
}
