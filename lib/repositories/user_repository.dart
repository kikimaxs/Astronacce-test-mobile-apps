import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class UserRepository {
  final AuthService _authService = AuthService();

  // Inisialisasi endpoint saat pertama kali digunakan
  static Future<void> _initializeEndpoint() async {
    await ApiConfig.baseUrl; // Ini akan melakukan pengecekan dan caching
  }

  Future<UsersResponse> getUsers({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.usersUrl;
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      
      print('🔄 Fetching users from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('👥 Users response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UsersResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired. Please login again.');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch users');
      }
    } catch (e) {
      print('❌ Get users error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Get users error: $e');
    }
  }

  Future<User> getUserById(String id) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.usersUrl;
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      print('🔄 Fetching user by ID: $id from: $baseUrl/$id');

      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('👤 User by ID response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to fetch user');
      }
    } catch (e) {
      print('❌ Get user by ID error: $e');
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Get user by ID error: $e');
    }
  }

  Future<User> createUser(User user) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.usersUrl;
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'address': user.address,
          'avatar': user.avatar,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('Create user response: $responseData'); // Debug log
        
        // Extract user from response
        if (responseData['user'] != null) {
          return User.fromJson(responseData['user']);
        } else {
          throw Exception('Invalid response format: missing user data');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create user');
      }
    } catch (e) {
      print('Error creating user: $e'); // Debug log
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Failed to create user: $e');
    }
  }

  Future<User> updateUser(User user) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.usersUrl;
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.put(
        Uri.parse('$baseUrl/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'address': user.address,
          'avatar': user.avatar,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['user'] != null) {
          return User.fromJson(responseData['user']);
        } else {
          return User.fromJson(responseData);
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to update user');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _initializeEndpoint();
      final baseUrl = await ApiConfig.usersUrl;
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete user');
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        // Reset cache dan coba endpoint lain
        ApiConfig.resetCache();
        throw Exception('Cannot connect to server. Trying alternative endpoint...');
      }
      throw Exception('Error deleting user: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      await _initializeEndpoint();
      final healthUrl = await ApiConfig.healthUrl;
      
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}