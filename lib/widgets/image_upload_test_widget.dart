import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';

class ImageUploadTestWidget extends StatefulWidget {
  const ImageUploadTestWidget({super.key});

  @override
  State<ImageUploadTestWidget> createState() => _ImageUploadTestWidgetState();
}

class _ImageUploadTestWidgetState extends State<ImageUploadTestWidget> {
  File? _selectedImage;
  String? _uploadedUrl;
  bool _isUploading = false;
  String _status = 'Pilih gambar untuk memulai test';
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Image Upload'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Image Preview
            if (_selectedImage != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pilih Gambar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_selectedImage != null && !_isUploading) ? _testUpload : null,
                    icon: _isUploading 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Test Upload'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Result URL
            if (_uploadedUrl != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Upload Berhasil!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _uploadedUrl!,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _testUrlInDialog(_uploadedUrl!),
                              icon: const Icon(Icons.preview),
                              label: const Text('Preview'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _validateUrl(_uploadedUrl!),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Validate'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedUrl = null;
          _status = 'Gambar dipilih. Siap untuk upload!';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error memilih gambar: $e';
      });
    }
  }

  Future<void> _testUpload() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isUploading = true;
      _status = 'Mengupload gambar ke hosting gratis...';
    });
    
    try {
      final imageUrl = await ImageUploadService.uploadImageWithRetry(
        imageFile: _selectedImage!,
        maxRetries: 3,
        retryDelay: 2,
      );
      
      if (imageUrl != null) {
        setState(() {
          _uploadedUrl = imageUrl;
          _status = 'Upload berhasil! URL siap digunakan.';
        });
      } else {
        setState(() {
          _status = 'Upload gagal ke semua hosting service.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error upload: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _validateUrl(String url) async {
    setState(() {
      _status = 'Memvalidasi URL...';
    });
    
    try {
      final isValid = await ImageUploadService.validateImageUrl(url);
      setState(() {
        _status = isValid 
            ? '✅ URL valid dan dapat diakses!'
            : '⚠️ URL tidak dapat divalidasi (mungkin masalah SSL)';
      });
    } catch (e) {
      setState(() {
        _status = 'Error validasi: $e';
      });
    }
  }

  void _testUrlInDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preview URL'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    Text('Error: $error'),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}