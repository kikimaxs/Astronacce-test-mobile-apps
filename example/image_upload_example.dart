import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../lib/services/image_upload_service.dart';
import '../lib/config/image_hosting_config.dart';

class ImageUploadExample extends StatefulWidget {
  @override
  _ImageUploadExampleState createState() => _ImageUploadExampleState();
}

class _ImageUploadExampleState extends State<ImageUploadExample> {
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  String _status = '';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      // 1. Pilih gambar
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
        _status = 'Gambar dipilih, memulai upload...';
        _isUploading = true;
      });

      // 2. Dapatkan info gambar
      final imageInfo = await ImageUploadService.getImageInfo(_selectedImage!);
      print('📊 Image Info: $imageInfo');

      // 3. Validasi gambar
      if (!imageInfo['isSupported']) {
        setState(() {
          _status = 'Format gambar tidak didukung: ${imageInfo['extension']}';
          _isUploading = false;
        });
        return;
      }

      if (!imageInfo['isValidSize']) {
        setState(() {
          _status = 'Ukuran gambar terlalu besar: ${imageInfo['sizeFormatted']}';
          _isUploading = false;
        });
        return;
      }

      // 4. Kompres gambar jika perlu
      setState(() {
        _status = 'Memproses gambar...';
      });

      final compressedImage = await ImageUploadService.compressImage(_selectedImage!);
      if (compressedImage == null) {
        setState(() {
          _status = 'Gagal memproses gambar';
          _isUploading = false;
        });
        return;
      }

      // 5. Upload dengan retry mechanism
      setState(() {
        _status = 'Mengupload gambar...';
      });

      final imageUrl = await ImageUploadService.uploadImageWithRetry(
        imageFile: compressedImage,
        maxRetries: ImageHostingConfig.maxRetries,
        retryDelay: ImageHostingConfig.retryDelaySeconds,
      );

      if (imageUrl != null) {
        // 6. Validasi URL
        setState(() {
          _status = 'Memvalidasi URL...';
        });

        final isValid = await ImageUploadService.validateImageUrl(imageUrl);
        
        if (isValid) {
          setState(() {
            _uploadedImageUrl = imageUrl;
            _status = 'Upload berhasil!';
          });
        } else {
          setState(() {
            _status = 'URL gambar tidak valid';
          });
        }
      } else {
        // 7. Fallback ke base64 jika upload hosting gagal
        setState(() {
          _status = 'Upload hosting gagal, menggunakan base64...';
        });

        final bytes = await compressedImage.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        
        setState(() {
          _uploadedImageUrl = base64String;
          _status = 'Menggunakan base64 sebagai fallback';
        });
      }

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Upload Example'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_status.isEmpty ? 'Pilih gambar untuk memulai' : _status),
                    if (_isUploading) ...[
                      SizedBox(height: 8),
                      LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Selected Image Preview
            if (_selectedImage != null) ...[
              Text(
                'Gambar Terpilih:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 16),
            ],

            // Uploaded Image Preview
            if (_uploadedImageUrl != null) ...[
              Text(
                'Hasil Upload:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _uploadedImageUrl!.startsWith('http')
                    ? Image.network(
                        _uploadedImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(child: Text('Error loading image'));
                        },
                      )
                    : Image.memory(
                        base64Decode(_uploadedImageUrl!.split(',')[1]),
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(height: 8),
              SelectableText(
                'URL: $_uploadedImageUrl',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 16),
            ],

            // Upload Button
            ElevatedButton(
              onPressed: _isUploading ? null : _pickAndUploadImage,
              child: Text(_isUploading ? 'Uploading...' : 'Pilih & Upload Gambar'),
            ),

            SizedBox(height: 16),

            // Configuration Info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfigurasi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Max Retries: ${ImageHostingConfig.maxRetries}'),
                    Text('Retry Delay: ${ImageHostingConfig.retryDelaySeconds}s'),
                    Text('Max File Size: ${ImageHostingConfig.maxFileSizeBytes / (1024 * 1024)}MB'),
                    Text('Supported Formats: ${ImageHostingConfig.supportedFormats.join(', ')}'),
                    Text('ImgBB API Key: ${ImageHostingConfig.imgbbApiKey == 'YOUR_IMGBB_API_KEY' ? 'Not configured' : 'Configured'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}