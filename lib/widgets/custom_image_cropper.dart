import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CustomImageCropper extends StatefulWidget {
  final double aspectRatio;
  final Function(File)? onImageCropped;
  final String? imagePath;

  const CustomImageCropper({
    super.key,
    this.aspectRatio = 1.0,
    this.onImageCropped,
    this.imagePath,
  });

  @override
  State<CustomImageCropper> createState() => _CustomImageCropperState();
}

class _CustomImageCropperState extends State<CustomImageCropper> {
  File? _selectedImage;
  ui.Image? _decodedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Crop parameters
  Offset _cropPosition = const Offset(50, 50);
  Size _cropSize = const Size(200, 200);
  Offset _imagePosition = Offset.zero;
  double _scale = 1.0;
  Size _imageDisplaySize = Size.zero;

  // Gesture handling
  Offset? _lastPanPoint;
  double? _lastScale;
  bool _isResizing = false;
  int _resizeCorner = -1; // 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right

  @override
  void initState() {
    super.initState();
    // If imagePath is provided, load it immediately
    if (widget.imagePath != null) {
      _loadProvidedImage();
    }
  }

  Future<void> _loadProvidedImage() async {
    try {
      final file = File(widget.imagePath!);
      
      // Validate file exists
      if (!await file.exists()) {
        _showSnackBar('File gambar tidak ditemukan.');
        return;
      }
      
      // Validate file size (10MB limit)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        _showSnackBar('Ukuran file terlalu besar. Maksimal 10MB.');
        return;
      }

      // Validate file format
      final extension = widget.imagePath!.toLowerCase();
      if (!extension.endsWith('.jpg') && 
          !extension.endsWith('.jpeg') && 
          !extension.endsWith('.png')) {
        _showSnackBar('Format file tidak didukung. Gunakan JPG atau PNG.');
        return;
      }

      setState(() {
        _selectedImage = file;
      });

      // Decode image
      await _loadImage();
      _resetCrop();
    } catch (e) {
      _showSnackBar('Gagal memuat gambar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Potong Foto Profile'),
        actions: [
          if (_selectedImage != null)
            TextButton(
              onPressed: _isLoading ? null : _cropImage,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Selesai'),
            ),
        ],
      ),
      body: _selectedImage == null ? _buildImagePicker() : _buildCropInterface(),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_photo_alternate,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Pilih foto untuk dipotong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Format: JPG, PNG • Maksimal: 10MB',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropInterface() {
    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Seret untuk memindahkan • Pinch untuk zoom • Seret sudut untuk resize',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Crop interface
        Expanded(
          child: Container(
            color: Colors.black,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: CropPainter(
                      image: _decodedImage,
                      cropPosition: _cropPosition,
                      cropSize: _cropSize,
                      imagePosition: _imagePosition,
                      scale: _scale,
                      imageDisplaySize: _imageDisplaySize,
                      aspectRatio: widget.aspectRatio,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _resetCrop,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Ganti'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Validate file size (10MB limit)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          _showSnackBar('Ukuran file terlalu besar. Maksimal 10MB.');
          return;
        }

        // Validate file format
        final extension = pickedFile.path.toLowerCase();
        if (!extension.endsWith('.jpg') && 
            !extension.endsWith('.jpeg') && 
            !extension.endsWith('.png')) {
          _showSnackBar('Format file tidak didukung. Gunakan JPG atau PNG.');
          return;
        }

        setState(() {
          _selectedImage = file;
        });

        // Decode image
        await _loadImage();
        _resetCrop();
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _loadImage() async {
    if (_selectedImage == null) return;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      setState(() {
        _decodedImage = frame.image;
      });
    } catch (e) {
      _showSnackBar('Gagal memuat gambar: $e');
    }
  }

  void _resetCrop() {
    if (_decodedImage == null) return;

    setState(() {
      _scale = 1.0;
      _imagePosition = Offset.zero;
      
      // Calculate initial crop size and position
      final screenSize = MediaQuery.of(context).size;
      final availableHeight = screenSize.height - 200; // Account for app bar and controls
      final availableWidth = screenSize.width;
      
      // Calculate image display size
      final imageAspectRatio = _decodedImage!.width / _decodedImage!.height;
      if (imageAspectRatio > availableWidth / availableHeight) {
        _imageDisplaySize = Size(availableWidth, availableWidth / imageAspectRatio);
      } else {
        _imageDisplaySize = Size(availableHeight * imageAspectRatio, availableHeight);
      }
      
      // Set initial crop size (80% of smaller dimension)
      final cropDimension = (_imageDisplaySize.width < _imageDisplaySize.height 
          ? _imageDisplaySize.width 
          : _imageDisplaySize.height) * 0.8;
      
      _cropSize = Size(cropDimension, cropDimension / widget.aspectRatio);
      
      // Center the crop
      _cropPosition = Offset(
        (availableWidth - _cropSize.width) / 2,
        (availableHeight - _cropSize.height) / 2,
      );
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastPanPoint = details.focalPoint;
    _lastScale = _scale;
    
    // Check if starting near a corner for resizing
    _isResizing = false;
    _resizeCorner = -1;
    
    final corners = [
      _cropPosition, // top-left
      Offset(_cropPosition.dx + _cropSize.width, _cropPosition.dy), // top-right
      Offset(_cropPosition.dx, _cropPosition.dy + _cropSize.height), // bottom-left
      _cropPosition + Offset(_cropSize.width, _cropSize.height), // bottom-right
    ];
    
    for (int i = 0; i < corners.length; i++) {
      final distance = (details.focalPoint - corners[i]).distance;
      if (distance < 30) {
        _isResizing = true;
        _resizeCorner = i;
        break;
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (_isResizing && _resizeCorner >= 0) {
        // Handle resizing
        _handleResize(details.focalPoint);
      } else if (details.scale != 1.0) {
        // Handle zooming
        final newScale = (_lastScale ?? 1.0) * details.scale;
        _scale = newScale.clamp(0.5, 3.0);
      } else {
        // Handle panning
        final delta = details.focalPoint - (_lastPanPoint ?? details.focalPoint);
        _imagePosition += delta;
        _lastPanPoint = details.focalPoint;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isResizing = false;
    _resizeCorner = -1;
    _lastPanPoint = null;
    _lastScale = null;
  }

  void _handleResize(Offset currentPoint) {
    final screenSize = MediaQuery.of(context).size;
    final minSize = 50.0;
    final maxSize = screenSize.width * 0.9;
    
    switch (_resizeCorner) {
      case 0: // top-left
        final newWidth = (_cropPosition.dx + _cropSize.width - currentPoint.dx).clamp(minSize, maxSize);
        final newHeight = newWidth / widget.aspectRatio;
        _cropSize = Size(newWidth, newHeight);
        _cropPosition = Offset(currentPoint.dx, currentPoint.dy);
        break;
      case 1: // top-right
        final newWidth = (currentPoint.dx - _cropPosition.dx).clamp(minSize, maxSize);
        final newHeight = newWidth / widget.aspectRatio;
        _cropSize = Size(newWidth, newHeight);
        _cropPosition = Offset(_cropPosition.dx, currentPoint.dy);
        break;
      case 2: // bottom-left
        final newWidth = (_cropPosition.dx + _cropSize.width - currentPoint.dx).clamp(minSize, maxSize);
        final newHeight = newWidth / widget.aspectRatio;
        _cropSize = Size(newWidth, newHeight);
        _cropPosition = Offset(currentPoint.dx, _cropPosition.dy);
        break;
      case 3: // bottom-right
        final newWidth = (currentPoint.dx - _cropPosition.dx).clamp(minSize, maxSize);
        final newHeight = newWidth / widget.aspectRatio;
        _cropSize = Size(newWidth, newHeight);
        break;
    }
  }

  Future<void> _cropImage() async {
    if (_selectedImage == null || _decodedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Read the original image file
      final bytes = await _selectedImage!.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        throw Exception('Gagal decode gambar');
      }

      // Calculate crop parameters relative to original image
      final screenSize = MediaQuery.of(context).size;
      final availableHeight = screenSize.height - 200;
      
      // Calculate the actual image position on screen
      final imageCenter = Offset(screenSize.width / 2, availableHeight / 2) + _imagePosition;
      final scaledImageSize = Size(_imageDisplaySize.width * _scale, _imageDisplaySize.height * _scale);
      
      final imageRect = Rect.fromCenter(
        center: imageCenter,
        width: scaledImageSize.width,
        height: scaledImageSize.height,
      );

      // Calculate crop area relative to the scaled image
      final cropRelativeX = (_cropPosition.dx - imageRect.left) / scaledImageSize.width;
      final cropRelativeY = (_cropPosition.dy - imageRect.top) / scaledImageSize.height;
      final cropRelativeWidth = _cropSize.width / scaledImageSize.width;
      final cropRelativeHeight = _cropSize.height / scaledImageSize.height;

      // Convert to original image coordinates
      final cropX = (cropRelativeX * originalImage.width).round().clamp(0, originalImage.width);
      final cropY = (cropRelativeY * originalImage.height).round().clamp(0, originalImage.height);
      final cropWidth = (cropRelativeWidth * originalImage.width).round().clamp(1, originalImage.width - cropX);
      final cropHeight = (cropRelativeHeight * originalImage.height).round().clamp(1, originalImage.height - cropY);

      // Crop the image
      final croppedImage = img.copyCrop(
        originalImage,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Save the cropped image to a temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(path.join(tempDir.path, fileName));
      
      final croppedBytes = img.encodeJpg(croppedImage, quality: 90);
      await croppedFile.writeAsBytes(croppedBytes);

      _showSnackBar('Gambar berhasil dipotong!');
      
      // Return the cropped file through Navigator.pop
      Navigator.of(context).pop(croppedFile);
    } catch (e) {
      _showSnackBar('Gagal memotong gambar: $e');
      print('Error cropping image: $e'); // For debugging
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class CropPainter extends CustomPainter {
  final ui.Image? image;
  final Offset cropPosition;
  final Size cropSize;
  final Offset imagePosition;
  final double scale;
  final Size imageDisplaySize;
  final double aspectRatio;

  CropPainter({
    required this.image,
    required this.cropPosition,
    required this.cropSize,
    required this.imagePosition,
    required this.scale,
    required this.imageDisplaySize,
    required this.aspectRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) {
      // Draw placeholder
      final paint = Paint()..color = Colors.grey[300]!;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    // Calculate image position and size
    final imageRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2) + imagePosition,
      width: imageDisplaySize.width * scale,
      height: imageDisplaySize.height * scale,
    );

    // Draw the image
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      imageRect,
      Paint(),
    );

    // Draw crop overlay (darken areas outside crop)
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);
    
    // Top
    if (cropPosition.dy > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, cropPosition.dy),
        overlayPaint,
      );
    }
    
    // Bottom
    final bottomY = cropPosition.dy + cropSize.height;
    if (bottomY < size.height) {
      canvas.drawRect(
        Rect.fromLTWH(0, bottomY, size.width, size.height - bottomY),
        overlayPaint,
      );
    }
    
    // Left
    if (cropPosition.dx > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, cropPosition.dy, cropPosition.dx, cropSize.height),
        overlayPaint,
      );
    }
    
    // Right
    final rightX = cropPosition.dx + cropSize.width;
    if (rightX < size.width) {
      canvas.drawRect(
        Rect.fromLTWH(rightX, cropPosition.dy, size.width - rightX, cropSize.height),
        overlayPaint,
      );
    }

    // Draw crop border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final cropRect = Rect.fromLTWH(
      cropPosition.dx,
      cropPosition.dy,
      cropSize.width,
      cropSize.height,
    );
    
    canvas.drawRect(cropRect, borderPaint);

    // Draw corner handles
    final handlePaint = Paint()..color = Colors.white;
    final handleBorderPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final corners = [
      cropPosition,
      Offset(cropPosition.dx + cropSize.width, cropPosition.dy),
      Offset(cropPosition.dx, cropPosition.dy + cropSize.height),
      cropPosition + Offset(cropSize.width, cropSize.height),
    ];
    
    for (final corner in corners) {
      canvas.drawCircle(corner, 10, handlePaint);
      canvas.drawCircle(corner, 10, handleBorderPaint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1;
    
    // Vertical lines
    for (int i = 1; i < 3; i++) {
      final x = cropPosition.dx + (cropSize.width / 3) * i;
      canvas.drawLine(
        Offset(x, cropPosition.dy),
        Offset(x, cropPosition.dy + cropSize.height),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = cropPosition.dy + (cropSize.height / 3) * i;
      canvas.drawLine(
        Offset(cropPosition.dx, y),
        Offset(cropPosition.dx + cropSize.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}