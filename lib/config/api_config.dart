import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  // ========================================
  // KONFIGURASI TESTING - UBAH SESUAI KEBUTUHAN
  // ========================================
  
  // Set ke true untuk menggunakan development/localhost
  // Set ke false untuk menggunakan production/vercel
  static const bool _useDevelopmentMode = false; // <-- UBAH INI UNTUK TESTING
  
  // URL endpoints
  static const String _vercelBaseUrl = 'https://astronance-api.vercel.app';
  static const String _developmentBaseUrl = 'http://localhost:3000';
  
  // Cache untuk menyimpan URL yang berhasil
  static String? _cachedBaseUrl;
  
  static Future<String> get baseUrl async {
    // Jika sudah ada cache, gunakan itu
    if (_cachedBaseUrl != null) {
      print('🔄 Using cached endpoint: $_cachedBaseUrl');
      return _cachedBaseUrl!;
    }
    
    // Tentukan URL berdasarkan mode testing
    if (_useDevelopmentMode) {
      print('🔧 Development mode enabled - using local endpoint');
      return await _getDevelopmentUrl();
    } else {
      print('🌐 Production mode enabled - using Vercel endpoint');
      return await _getProductionUrl();
    }
  }
  
  // Method untuk mendapatkan URL development
  static Future<String> _getDevelopmentUrl() async {
    String localUrl = _getLocalUrl();
    print('🏠 Testing local endpoint: $localUrl');
    
    if (await _isEndpointAvailable(localUrl)) {
      _cachedBaseUrl = localUrl;
      print('✅ Local endpoint is available: $localUrl');
      return localUrl;
    } else {
      print('❌ Local endpoint not available, falling back to Vercel');
      return await _getProductionUrl();
    }
  }
  
  // Method untuk mendapatkan URL production
  static Future<String> _getProductionUrl() async {
    print('🌐 Testing Vercel endpoint: $_vercelBaseUrl');
    
    if (await _isEndpointAvailable(_vercelBaseUrl)) {
      _cachedBaseUrl = _vercelBaseUrl;
      print('✅ Vercel endpoint is available: $_vercelBaseUrl');
      return _vercelBaseUrl;
    } else {
      print('⚠️ Vercel endpoint not available, using as fallback anyway');
      _cachedBaseUrl = _vercelBaseUrl;
      return _vercelBaseUrl;
    }
  }
  
  static String _getLocalUrl() {
    if (kIsWeb) {
      return _developmentBaseUrl;
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // IP khusus Android Emulator
    } else if (Platform.isIOS) {
      return _developmentBaseUrl; // iOS Simulator bisa pakai localhost
    } else {
      return _developmentBaseUrl; // Web/Desktop
    }
  }
  
  static Future<bool> _isEndpointAvailable(String url) async {
    try {
      print('🔍 Checking endpoint: $url/health');
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'AstronanceApp/1.0',
        },
      ).timeout(const Duration(seconds: 10)); // Increased timeout
      
      print('📡 Response from $url: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Endpoint $url is healthy');
        return true;
      } else {
        print('❌ Endpoint $url returned status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Endpoint $url error: $e');
      return false;
    }
  }
  
  // Method untuk reset cache (berguna untuk testing atau refresh)
  static void resetCache() {
    print('🔄 Resetting API cache');
    _cachedBaseUrl = null;
  }
  
  // Method untuk force refresh endpoint
  static Future<String> refreshEndpoint() async {
    resetCache();
    return await baseUrl;
  }
  
  // Method untuk switch mode secara programmatic (opsional)
  static Future<String> forceUseDevelopment() async {
    resetCache();
    return await _getDevelopmentUrl();
  }
  
  static Future<String> forceUseProduction() async {
    resetCache();
    return await _getProductionUrl();
  }
  
  // Getter untuk URL spesifik
  static Future<String> get authUrl async => '${await baseUrl}/api/auth';
  static Future<String> get usersUrl async => '${await baseUrl}/api/users';
  static Future<String> get healthUrl async => '${await baseUrl}/health';
  
  // Method untuk mendapatkan URL secara synchronous (untuk backward compatibility)
  static String get baseUrlSync {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }
    return _useDevelopmentMode ? _getLocalUrl() : _vercelBaseUrl;
  }
  
  static String get authUrlSync => '$baseUrlSync/api/auth';
  static String get usersUrlSync => '$baseUrlSync/api/users';
  static String get healthUrlSync => '$baseUrlSync/health';
  
  // Method untuk test koneksi manual
  static Future<Map<String, dynamic>> testAllEndpoints() async {
    final results = <String, dynamic>{};
    
    // Test Vercel
    results['vercel'] = {
      'url': _vercelBaseUrl,
      'available': await _isEndpointAvailable(_vercelBaseUrl),
    };
    
    // Test Local
    final localUrl = _getLocalUrl();
    results['local'] = {
      'url': localUrl,
      'available': await _isEndpointAvailable(localUrl),
    };
    
    // Current mode info
    results['currentMode'] = {
      'isDevelopmentMode': _useDevelopmentMode,
      'activeUrl': await baseUrl,
    };
    
    return results;
  }
  
  // Getter untuk mengetahui mode saat ini
  static bool get isDevelopmentMode => _useDevelopmentMode;
  static String get currentModeDescription => 
      _useDevelopmentMode ? 'Development (Local)' : 'Production (Vercel)';
}