import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../models/user.dart';
import '../widgets/custom_image_cropper.dart';
import '../services/image_upload_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current user data
    _nameController.text = widget.user.name;
    _phoneController.text = widget.user.phone ?? '';
    _addressController.text = widget.user.address ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menyimpan perubahan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateProfile();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final String? method = await _showImagePickerDialog();
      if (method == null) return;

      if (method == 'crop') {
        final ImageSource? source = await _showImageSourceDialog();
        if (source == null) return;

        final XFile? image = await _picker.pickImage(source: source);
        if (image != null) {
          final File? croppedImage = await Navigator.push<File>(
            context,
            MaterialPageRoute(
              builder: (context) => CustomImageCropper(
                imagePath: image.path,
              ),
            ),
          );
          
          if (croppedImage != null) {
            setState(() {
              _selectedImage = croppedImage;
            });
            _showSnackBar('Foto berhasil dipotong dan dipilih!');
          }
        }
      } else {
        final ImageSource? source = await _showImageSourceDialog();
        if (source == null) return;

        final XFile? image = await _picker.pickImage(source: source);
        
        if (image != null) {
          setState(() {
            _selectedImage = File(image.path);
          });
          _showSnackBar('Foto berhasil dipilih!');
        }
      }
    } catch (e) {
      _showSnackBar('Error memilih gambar: $e', isError: true);
    }
  }

  Future<String?> _showImagePickerDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Metode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.crop),
                title: const Text('Potong Foto'),
                subtitle: const Text('Pilih dan potong foto sesuai keinginan'),
                onTap: () => Navigator.of(context).pop('crop'),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Pilih Langsung'),
                subtitle: const Text('Pilih foto tanpa memotong'),
                onTap: () => Navigator.of(context).pop('simple'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Upload gambar ke hosting gratis dan return URL (versi yang diperbaiki)
  Future<String?> _uploadImageToHosting(File imageFile) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      _showSnackBar('Mengupload gambar...', isError: false);
      
      // Kompres gambar jika perlu
      final compressedImage = await ImageUploadService.compressImage(imageFile);
      if (compressedImage == null) {
        throw Exception('Gagal memproses gambar');
      }

      // Upload dengan retry mechanism
      final imageUrl = await ImageUploadService.uploadImageWithRetry(
        imageFile: compressedImage,
        maxRetries: 3,
        retryDelay: 2,
      );

      if (imageUrl != null) {
        print('✅ Upload berhasil, URL: $imageUrl');
        
        // Validasi URL yang dikembalikan
        final isValid = await ImageUploadService.validateImageUrl(imageUrl);
        if (isValid) {
          _showSnackBar('✅ Gambar berhasil diupload dan tervalidasi!');
          return imageUrl;
        } else {
          // Jika validasi gagal tapi URL dari hosting terpercaya, tetap gunakan
          final uri = Uri.parse(imageUrl);
          final trustedDomains = ['i.ibb.co', 'ibb.co', 'i.imgur.com', 'imgur.com', 'files.catbox.moe'];
          
          if (trustedDomains.any((domain) => uri.host.contains(domain))) {
            print('ℹ️ URL dari hosting terpercaya, mengabaikan error validasi SSL');
            _showSnackBar('✅ Gambar berhasil diupload! (SSL validation bypassed)');
            return imageUrl;
          } else {
            throw Exception('URL gambar tidak valid dan bukan dari hosting terpercaya');
          }
        }
      } else {
        throw Exception('Gagal mengupload gambar ke semua hosting');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      _showSnackBar('Gagal mengupload gambar: $e', isError: true);
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  /// Fallback: Convert image to base64 jika upload hosting gagal
  Future<String?> _convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      String? avatarData;
      
      if (_selectedImage != null) {
        // Coba upload ke hosting gratis terlebih dahulu
        avatarData = await _uploadImageToHosting(_selectedImage!);
        
        // Jika upload hosting gagal, fallback ke base64
        if (avatarData == null) {
          _showSnackBar('Upload hosting gagal, menggunakan base64...', isError: false);
          avatarData = await _convertImageToBase64(_selectedImage!);
          
          if (avatarData == null) {
            _showSnackBar('Gagal memproses gambar', isError: true);
            return;
          }
        }
        
        print('🖼️ Avatar data: ${avatarData.startsWith('http') ? 'URL' : 'base64'} (${avatarData.length} chars)');
      }

      // Add detailed logging for the request
      print('📤 Profile update request:');
      print('  Name: ${_nameController.text.trim()}');
      print('  Phone: ${_phoneController.text.trim().isEmpty ? 'null' : _phoneController.text.trim()}');
      print('  Address: ${_addressController.text.trim().isEmpty ? 'null' : _addressController.text.trim()}');
      print('  Avatar: ${avatarData != null ? (avatarData.startsWith('http') ? 'URL' : 'base64 data') : 'null'}');

      context.read<AuthBloc>().add(
        AuthProfileUpdateRequested(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          avatar: avatarData,
        ),
      );
    }
  }

  Widget _buildProfileImage() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[400],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (widget.user.avatar?.isNotEmpty == true
                          ? NetworkImage(widget.user.avatar!)
                          : null) as ImageProvider?,
                  child: _selectedImage == null && (widget.user.avatar?.isEmpty ?? true)
                      ? Text(
                          widget.user.name.isNotEmpty 
                              ? widget.user.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: _isUploadingImage 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                    onPressed: _isUploadingImage || _isLoading ? null : _pickImage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap untuk mengubah foto profil',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          if (_isUploadingImage)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Mengupload gambar...',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: (_isLoading || _isUploadingImage) ? null : _showConfirmDialog,
            child: const Text(
              'SIMPAN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() {
              _isLoading = true;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
            
            if (state is AuthProfileUpdateSuccess) {
              _showSnackBar('Profile berhasil diperbarui!');
              Navigator.of(context).pop(state.user); // Return updated user
            } else if (state is AuthError) {
              _showSnackBar(state.message, isError: true);
            }
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image Section
                _buildProfileImage(),
                const SizedBox(height: 32),

                // User Info Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informasi Akun',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.user.email,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Bergabung: ${_formatDate(widget.user.createdAt)}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    helperText: 'Masukkan nama lengkap Anda',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    if (value.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                  enabled: !_isLoading && !_isUploadingImage,
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    helperText: 'Masukkan nomor telepon dimulai dengan 08 (opsional)',
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.length < 10) {
                        return 'Nomor telepon minimal 10 digit';
                      }
                      if (!value.startsWith('08')) {
                        return 'Nomor telepon harus dimulai dengan 08';
                      }
                    }
                    return null;
                  },
                  enabled: !_isLoading && !_isUploadingImage,
                ),
                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    helperText: 'Masukkan alamat lengkap (opsional)',
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (value.trim().length < 5) {
                        return 'Alamat minimal 5 karakter';
                      }
                    }
                    return null;
                  },
                  enabled: !_isLoading && !_isUploadingImage,
                ),
                const SizedBox(height: 32),

                // Loading indicator
                if (_isLoading || _isUploadingImage)
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          _isUploadingImage 
                              ? 'Mengupload gambar...' 
                              : 'Menyimpan perubahan...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}