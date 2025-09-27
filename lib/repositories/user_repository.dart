import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/auth_service.dart';

class UserRepository {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/users';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/users';
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api/users';
    } else {
      return 'http://localhost:3000/api/users';
    }
  }

  final AuthService _authService = AuthService();

  Future<UsersResponse> getUsers({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return UsersResponse.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to load users');
      }
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  Future<User> getUserById(int id) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token');

      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to load user');
      }
    } catch (e) {
      throw Exception('Error loading user: $e');
    }
  }

  Future<User> createUser(User user) async {
    try {
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
      throw Exception('Failed to create user: $e');
    }
  }

  Future<User> updateUser(User user) async {
    try {
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
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
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
      throw Exception('Error deleting user: $e');
    }
  }

  Future<bool> testConnection() async {
    try {
      final healthUrl = baseUrl.replaceAll('/api/users', '/health');
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