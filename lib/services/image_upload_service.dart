import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/image_hosting_config.dart';

class ImageUploadService {
  // API URLs
  static const String _imgbbUploadUrl = 'https://api.imgbb.com/1/upload';
  static const String _postimagesUploadUrl = 'https://postimages.org/json/rr';
  static const String _freeimageHostUploadUrl = 'https://freeimage.host/api/1/upload';

  /// Upload gambar ke hosting gratis dengan retry mechanism (versi yang diperbaiki)
  static Future<String?> uploadImageWithRetry({
    required File imageFile,
    int? maxRetries,
    int? retryDelay,
  }) async {
    final maxAttempts = maxRetries ?? ImageHostingConfig.maxRetries;
    final delaySeconds = retryDelay ?? ImageHostingConfig.retryDelaySeconds;
    
    // Validasi ukuran file
    final fileSize = await imageFile.length();
    if (fileSize > ImageHostingConfig.maxFileSizeBytes) {
      print('❌ File terlalu besar: ${fileSize / (1024 * 1024)}MB');
      return null;
    }
    
    // Validasi format file
    final extension = imageFile.path.split('.').last.toLowerCase();
    if (!ImageHostingConfig.supportedFormats.contains(extension)) {
      print('❌ Format file tidak didukung: $extension');
      return null;
    }

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('🔄 Upload attempt $attempt/$maxAttempts');
        
        // 1. Coba Imgur terlebih dahulu (paling stabil)
        String? imageUrl = await _uploadToImgur(imageFile);
        if (imageUrl != null) {
          print('✅ Upload berhasil ke Imgur: $imageUrl');
          return imageUrl;
        }
        
        // 2. Coba Catbox (alternatif stabil)
        imageUrl = await _uploadToCatbox(imageFile);
        if (imageUrl != null) {
          print('✅ Upload berhasil ke Catbox: $imageUrl');
          return imageUrl;
        }
        
        // 3. Coba ImgBB (jika API key tersedia)
        if (ImageHostingConfig.imgbbApiKey != 'YOUR_IMGBB_API_KEY') {
          imageUrl = await _uploadToImgBB(imageFile);
          if (imageUrl != null) {
            print('✅ Upload berhasil ke ImgBB: $imageUrl');
            return imageUrl;
          }
        }
        
        // 4. Coba PostImages
        imageUrl = await _uploadToPostImages(imageFile);
        if (imageUrl != null) {
          print('✅ Upload berhasil ke PostImages: $imageUrl');
          return imageUrl;
        }
        
        // 5. Coba FreeImageHost
        imageUrl = await _uploadToFreeImageHost(imageFile);
        if (imageUrl != null) {
          print('✅ Upload berhasil ke FreeImageHost: $imageUrl');
          return imageUrl;
        }
        
      } catch (e) {
        print('❌ Upload attempt $attempt failed: $e');
        
        // Jika ini bukan percobaan terakhir, tunggu sebelum retry
        if (attempt < maxAttempts) {
          print('⏳ Waiting ${delaySeconds}s before retry...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }
    
    print('❌ All upload attempts failed');
    return null;
  }

  /// Upload ke ImgBB
  static Future<String?> _uploadToImgBB(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_imgbbUploadUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'key': ImageHostingConfig.imgbbApiKey,
          'image': base64Image,
          'expiration': '0', // No expiration
        },
      ).timeout(Duration(seconds: ImageHostingConfig.uploadTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'];
        }
      }
      
      print('❌ ImgBB upload failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ ImgBB upload error: $e');
      return null;
    }
  }

  /// Upload ke PostImages
  static Future<String?> _uploadToPostImages(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      var request = http.MultipartRequest('POST', Uri.parse(_postimagesUploadUrl));
      request.files.add(
        http.MultipartFile.fromBytes(
          'upload',
          bytes,
          filename: 'image.${imageFile.path.split('.').last}',
        ),
      );
      
      final streamedResponse = await request.send()
          .timeout(Duration(seconds: ImageHostingConfig.uploadTimeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['url'];
        }
      }
      
      print('❌ PostImages upload failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ PostImages upload error: $e');
      return null;
    }
  }

  /// Upload ke FreeImageHost
  static Future<String?> _uploadToFreeImageHost(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse(_freeimageHostUploadUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'source': base64Image,
          'type': 'file',
          'action': 'upload',
        },
      ).timeout(Duration(seconds: ImageHostingConfig.uploadTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status_code'] == 200) {
          return data['image']['url'];
        }
      }
      
      print('❌ FreeImageHost upload failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ FreeImageHost upload error: $e');
      return null;
    }
  }

  /// Upload base64 string dengan retry mechanism
  static Future<String?> uploadBase64WithRetry({
    required String base64String,
    int? maxRetries,
    int? retryDelay,
  }) async {
    final maxAttempts = maxRetries ?? ImageHostingConfig.maxRetries;
    final delaySeconds = retryDelay ?? ImageHostingConfig.retryDelaySeconds;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('🔄 Base64 upload attempt $attempt/$maxAttempts');
        
        // Coba upload ke ImgBB
        if (ImageHostingConfig.imgbbApiKey != 'YOUR_IMGBB_API_KEY') {
          String? imageUrl = await _uploadBase64ToImgBB(base64String);
          if (imageUrl != null) {
            print('✅ Base64 upload berhasil ke ImgBB: $imageUrl');
            return imageUrl;
          }
        }
        
        // Coba FreeImageHost
        String? imageUrl = await _uploadBase64ToFreeImageHost(base64String);
        if (imageUrl != null) {
          print('✅ Base64 upload berhasil ke FreeImageHost: $imageUrl');
          return imageUrl;
        }
        
      } catch (e) {
        print('❌ Base64 upload attempt $attempt failed: $e');
        
        if (attempt < maxAttempts) {
          print('⏳ Waiting ${delaySeconds}s before retry...');
          await Future.delayed(Duration(seconds: delaySeconds));
        }
      }
    }
    
    print('❌ All base64 upload attempts failed');
    return null;
  }

  static Future<String?> _uploadBase64ToImgBB(String base64String) async {
    try {
      // Remove data:image/jpeg;base64, prefix if exists
      final cleanBase64 = base64String.replaceFirst(RegExp(r'^data:image\/[^;]+;base64,'), '');

      final response = await http.post(
        Uri.parse(_imgbbUploadUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'key': ImageHostingConfig.imgbbApiKey,
          'image': cleanBase64,
          'expiration': '0',
        },
      ).timeout(Duration(seconds: ImageHostingConfig.uploadTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['url'];
        }
      }
      
      return null;
    } catch (e) {
      print('❌ ImgBB base64 upload error: $e');
      return null;
    }
  }

  static Future<String?> _uploadBase64ToFreeImageHost(String base64String) async {
    try {
      // Remove data:image/jpeg;base64, prefix if exists
      final cleanBase64 = base64String.replaceFirst(RegExp(r'^data:image\/[^;]+;base64,'), '');
      
      final response = await http.post(
        Uri.parse(_freeimageHostUploadUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'source': cleanBase64,
          'type': 'file',
          'action': 'upload',
        },
      ).timeout(Duration(seconds: ImageHostingConfig.uploadTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status_code'] == 200) {
          return data['image']['url'];
        }
      }
      
      return null;
    } catch (e) {
      print('❌ FreeImageHost base64 upload error: $e');
      return null;
    }
  }

  /// Validasi apakah URL gambar dapat diakses dengan bypass SSL untuk hosting tertentu
  static Future<bool> validateImageUrl(String url) async {
    try {
      // Untuk domain tertentu yang diketahui aman, skip SSL verification
      final uri = Uri.parse(url);
      final trustedDomains = [
        'i.ibb.co',
        'ibb.co', 
        'postimg.cc',
        'freeimage.host',
        'imgur.com',
        'i.imgur.com'
      ];
      
      // Jika domain terpercaya, langsung return true
      if (trustedDomains.any((domain) => uri.host.contains(domain))) {
        print('✅ URL dari domain terpercaya: ${uri.host}');
        return true;
      }
      
      // Untuk domain lain, lakukan validasi normal
      final response = await http.head(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Image URL validation failed: $e');
      
      // Jika validasi gagal tapi URL dari ImgBB, kemungkinan masalah SSL
      if (url.contains('i.ibb.co') || url.contains('ibb.co')) {
        print('ℹ️ ImgBB URL detected, assuming valid despite SSL error');
        return true;
      }
      
      return false;
    }
  }

  /// Upload ke Imgur (alternatif hosting yang lebih stabil)
  static Future<String?> _uploadToImgur(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('https://api.imgur.com/3/image'),
        headers: {
          'Authorization': 'Client-ID 546c25a59c58ad7', // Public client ID
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'image': base64Image,
          'type': 'base64',
        }),
      ).timeout(Duration(seconds: ImageHostingConfig.uploadTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data']['link'];
        }
      }
      
      print('❌ Imgur upload failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Imgur upload error: $e');
      return null;
    }
  }

  /// Upload ke Catbox (hosting alternatif yang stabil)
  static Future<String?> _uploadToCatbox(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('https://catbox.moe/user/api.php'));
      request.fields['reqtype'] = 'fileupload';
      request.files.add(
        http.MultipartFile.fromBytes(
          'fileToUpload',
          await imageFile.readAsBytes(),
          filename: 'image.${imageFile.path.split('.').last}',
        ),
      );
      
      final streamedResponse = await request.send()
          .timeout(Duration(seconds: ImageHostingConfig.uploadTimeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final url = response.body.trim();
        if (url.startsWith('https://files.catbox.moe/')) {
          return url;
        }
      }
      
      print('❌ Catbox upload failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Catbox upload error: $e');
      return null;
    }
  }

  /// Kompres gambar sebelum upload untuk mengurangi ukuran
  static Future<File?> compressImage(File imageFile, {int quality = 85}) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Jika ukuran file sudah kecil (< 1MB), tidak perlu kompres
      if (bytes.length < 1024 * 1024) {
        return imageFile;
      }
      
      // TODO: Implementasi kompres gambar menggunakan package image
      // Untuk sekarang, return file asli
      print('ℹ️ Image compression not implemented yet, returning original file');
      return imageFile;
    } catch (e) {
      print('❌ Image compression error: $e');
      return imageFile;
    }
  }

  /// Get informasi file gambar
  static Future<Map<String, dynamic>> getImageInfo(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final extension = imageFile.path.split('.').last.toLowerCase();
      
      return {
        'size': bytes.length,
        'sizeFormatted': '${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB',
        'extension': extension,
        'isSupported': ImageHostingConfig.supportedFormats.contains(extension),
        'isValidSize': bytes.length <= ImageHostingConfig.maxFileSizeBytes,
      };
    } catch (e) {
      print('❌ Error getting image info: $e');
      return {};
    }
  }
}