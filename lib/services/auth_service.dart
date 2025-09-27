import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class AuthService {
  // Inisialisasi endpoint saat pertama kali digunakan
  static Future<void> _initializeEndpoint() async {
    await ApiConfig.baseUrl; // Ini akan melakukan pengecekan dan caching
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.authUrl;
      
      print('🔄 Registering user: $email');
      print('🌐 Using URL: $baseUrl/register');
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📝 Registration response: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'];
        
        await _saveAuthData(user, token);
        return user;
      } else {
        final error = json.decode(response.body);
        if (error['errors'] != null && error['errors'] is List) {
          final errorMessages = (error['errors'] as List)
              .map((e) => e['msg'] ?? e['message'] ?? 'Unknown error')
              .join(', ');
          throw Exception(errorMessages);
        }
        throw Exception(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print('❌ Registration error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Registration error: $e');
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.authUrl;
      
      print('🔄 Logging in user: $email');
      print('🌐 Using URL: $baseUrl/login');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📝 Login response: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'];
        
        await _saveAuthData(user, token);
        return user;
      } else {
        final error = json.decode(response.body);
        if (error['errors'] != null && error['errors'] is List) {
          final errorMessages = (error['errors'] as List)
              .map((e) => e['msg'] ?? e['message'] ?? 'Unknown error')
              .join(', ');
          throw Exception(errorMessages);
        }
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.authUrl;
      
      print('🔄 Sending forgot password request for: $email');
      print('🌐 Using URL: $baseUrl/forgot-password');
      print('🔧 Current API mode: ${ApiConfig.currentModeDescription}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'AstronanceApp/1.0',
        },
        body: json.encode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 15));

      print('📝 Forgot password response: ${response.statusCode}');
      print('📝 Response headers: ${response.headers}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Password reset email sent successfully');
        final responseData = json.decode(response.body);
        return {
          'message': responseData['message'] ?? 'Reset instructions sent to your email',
          'resetToken': responseData['resetToken'], // May be null in production
          'expiresAt': responseData['expiresAt'], // May be null in production
        };
      } else {
        final error = json.decode(response.body);
        print('❌ Server error response: $error');
        throw Exception(error['error'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      print('❌ Forgot password error: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('TimeoutException')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Forgot password error: $e');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.authUrl;
      
      print('🔄 Resetting password with token: $token');
      print('🌐 Using URL: $baseUrl/reset-password');
      
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'token': token,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      print('🔐 Reset password response: ${response.statusCode}');
      print('🔐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Password reset successful',
        };
      } else {
        final error = json.decode(response.body);
        if (error['errors'] != null && error['errors'] is List) {
          final errorMessages = (error['errors'] as List)
              .map((e) => e['msg'] ?? e['message'] ?? 'Unknown error')
              .join(', ');
          throw Exception(errorMessages);
        }
        throw Exception(error['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('❌ Reset password error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Reset password error: $e');
    }
  }

  Future<User> updateProfile({
    required String name,
    String? phone,
    String? address,
    String? avatar,
  }) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.authUrl;
      
      print('🔄 Updating profile for: $name');
      final token = await getToken();
      if (token == null) throw Exception('No authentication token');

      final body = <String, dynamic>{'name': name};
      if (phone != null && phone.isNotEmpty) body['phone'] = phone;
      if (address != null && address.isNotEmpty) body['address'] = address;
      if (avatar != null && avatar.isNotEmpty) body['avatar'] = avatar;

      print('🌐 Using URL: $baseUrl/profile');
      print('📝 Update data: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      print('📝 Update profile response: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle new response format with message and user
        final userData = data['user'] ?? data;
        final user = User.fromJson(userData);
        
        // Update stored user data
        await _updateStoredUser(user);
        print('✅ Profile updated successfully');
        return user;
      } else if (response.statusCode == 401) {
        // Token is invalid or expired
        await logout();
        throw Exception('Authentication expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('User not found. Please contact support.');
      } else {
        final error = json.decode(response.body);
        if (error['errors'] != null && error['errors'] is List) {
          final errorMessages = (error['errors'] as List)
              .map((e) => e['msg'] ?? e['message'] ?? 'Unknown error')
              .join(', ');
          throw Exception(errorMessages);
        }
        throw Exception(error['error'] ?? 'Failed to update profile');
      }
    } catch (e) {
      print('❌ Profile update error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      
      // If it's a "User not found" error, suggest re-authentication
      if (e.toString().contains('User not found')) {
        await logout();
        throw Exception('User session expired. Please login again.');
      }
      
      throw Exception('Profile update error: $e');
    }
  }

  // Method baru untuk direct password reset
  Future<Map<String, dynamic>> directPasswordReset({
    required String email,
    required String newPassword,
  }) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.authUrl;
      
      print('🔄 Direct password reset for: $email');
      print('🌐 Using URL: $baseUrl/direct-password-reset');
      
      final response = await http.post(
        Uri.parse('$baseUrl/direct-password-reset'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 15));

      print('🔐 Direct password reset response: ${response.statusCode}');
      print('🔐 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Password berhasil diubah',
          'user': data['user'], // User data yang sudah diupdate
        };
      } else {
        final error = json.decode(response.body);
        if (error['errors'] != null && error['errors'] is List) {
          final errorMessages = (error['errors'] as List)
              .map((e) => e['msg'] ?? e['message'] ?? 'Unknown error')
              .join(', ');
          throw Exception(errorMessages);
        }
        throw Exception(error['error'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('❌ Direct password reset error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Direct password reset error: $e');
    }
  }

  Future<void> _saveAuthData(User user, String token) async {
    try {
      print('💾 Saving auth data for user: ${user.email}');
      print('🔑 Token: $token');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_data', json.encode(user.toJson()));
      
      print('✅ Auth data saved successfully');
    } catch (e) {
      print('❌ Error saving auth data: $e');
      throw Exception('Failed to save authentication data');
    }
  }

  Future<void> _updateStoredUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(user.toJson()));
    } catch (e) {
      print('❌ Error updating stored user: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        print('🔍 Retrieved token: Found');
        print('🔑 JWT Token for backend testing:');
        print('Bearer $token');
        print('📋 Raw token: $token');
        print('─' * 50);
      } else {
        print('🔍 Retrieved token: Not found');
      }
      
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final userJson = json.decode(userData);
        return User.fromJson(userJson);
      }
      return null;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      print('🚪 User logged out successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
      throw Exception('Logout failed');
    }
  }

  // Email validation helper
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Password strength validation helper
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final result = <String, dynamic>{
      'isValid': false,
      'score': 0,
      'feedback': <String>[],
    };

    if (password.length < 6) {
      result['feedback'].add('Password must be at least 6 characters long');
    } else {
      result['score'] += 1;
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      result['score'] += 1;
    } else {
      result['feedback'].add('Add uppercase letters for stronger security');
    }

    if (password.contains(RegExp(r'[a-z]'))) {
      result['score'] += 1;
    } else {
      result['feedback'].add('Add lowercase letters for stronger security');
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      result['score'] += 1;
    } else {
      result['feedback'].add('Add numbers for stronger security');
    }

    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      result['score'] += 1;
    } else {
      result['feedback'].add('Add special characters for stronger security');
    }

    result['isValid'] = password.length >= 6;
    return result;
  }

  Future<User> fetchCurrentUserProfile() async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.authUrl;
      
      final token = await getToken();
      if (token == null) throw Exception('No authentication token');

      print('🔄 Fetching current user profile...');
      print('🌐 Using URL: $baseUrl/profile');

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print('📝 Fetch profile response: ${response.statusCode}');
      print('📝 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['user'] ?? data;
        final user = User.fromJson(userData);
        
        // Update stored user data
        await _updateStoredUser(user);
        print('✅ Profile fetched successfully');
        return user;
      } else if (response.statusCode == 401) {
        // Token is invalid or expired
        await logout();
        throw Exception('Authentication expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('User not found. Please contact support.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      print('❌ Fetch profile error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      rethrow;
    }
  }
}