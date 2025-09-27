import 'dart:io';
import '../lib/services/image_upload_service.dart';

/// Test script untuk mencoba berbagai hosting service
void main() async {
  // Ganti dengan path gambar yang valid
  final testImagePath = '/path/to/test/image.jpg';
  final testImage = File(testImagePath);
  
  if (!await testImage.exists()) {
    print('❌ File test tidak ditemukan: $testImagePath');
    return;
  }
  
  print('🧪 Testing image upload ke berbagai hosting...');
  print('📁 File: ${testImage.path}');
  print('📏 Size: ${(await testImage.length() / 1024).toStringAsFixed(2)} KB');
  
  // Test upload dengan retry
  final result = await ImageUploadService.uploadImageWithRetry(
    imageFile: testImage,
    maxRetries: 2,
    retryDelay: 1,
  );
  
  if (result != null) {
    print('✅ Upload berhasil!');
    print('🔗 URL: $result');
    
    // Test validasi URL
    print('\n🔍 Testing URL validation...');
    final isValid = await ImageUploadService.validateImageUrl(result);
    print('✅ URL valid: $isValid');
    
    // Test akses URL
    print('\n🌐 Testing URL accessibility...');
    await testUrlAccess(result);
  } else {
    print('❌ Upload gagal ke semua hosting service');
  }
}

Future<void> testUrlAccess(String url) async {
  try {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final httpResponse = await response.close();
    
    print('📊 Status Code: ${httpResponse.statusCode}');
    print('📋 Headers: ${httpResponse.headers}');
    
    if (httpResponse.statusCode == 200) {
      print('✅ URL dapat diakses dengan baik');
    } else {
      print('⚠️ URL mengembalikan status code: ${httpResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Error mengakses URL: $e');
  }
}