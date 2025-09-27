import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

class AdvancedImageCropper extends StatefulWidget {
  final Function(File) onImageCropped;
  final double aspectRatio;
  final String title;
  final int maxWidth;
  final int maxHeight;

  const AdvancedImageCropper({
    super.key,
    required this.onImageCropped,
    this.aspectRatio = 1.0,
    this.title = 'Potong Foto',
    this.maxWidth = 512,
    this.maxHeight = 512,
  });

  @override
  State<AdvancedImageCropper> createState() => _AdvancedImageCropperState();
}

class _AdvancedImageCropperState extends State<AdvancedImageCropper> {
  File? _selectedImage;
  ui.Image? _decodedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isProcessing = false;
  
  // Crop area properties
  Rect _cropRect = const Rect.fromLTWH(50, 50, 200, 200);
  double _scale = 1.0;
  Offset _imageOffset = Offset.zero;
  Size _imageDisplaySize = Size.zero;
  Size _containerSize = Size.zero;
  
  // Gesture properties
  Offset? _lastPanPosition;
  double? _lastScale;
  bool _isResizing = false;
  String _resizeCorner = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
        elevation: 0,
      ),
      body: _selectedImage == null ? _buildImagePicker() : _buildCropInterface(),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.add_photo_alternate,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sesuaikan area pemotongan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Seret untuk memindahkan • Pinch untuk zoom • Seret sudut untuk mengubah ukuran',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Format: JPG, PNG • Maksimal: 10MB',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerButton(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildPickerButton(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildCropInterface() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Column(
      children: [
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Seret untuk memindahkan area • Pinch untuk zoom • Seret sudut untuk resize',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        
        // Crop interface
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _containerSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                onScaleEnd: _onScaleEnd,
                child: CustomPaint(
                  size: _containerSize,
                  painter: ImageCropPainter(
                    image: _decodedImage,
                    cropRect: _cropRect,
                    imageOffset: _imageOffset,
                    scale: _scale,
                    containerSize: _containerSize,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.refresh,
                label: 'Reset',
                onPressed: _resetCrop,
              ),
              _buildControlButton(
                icon: Icons.photo_library,
                label: 'Ganti Foto',
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              _buildControlButton(
                icon: Icons.aspect_ratio,
                label: 'Rasio',
                onPressed: _toggleAspectRatio,
              ),
              _buildControlButton(
                icon: Icons.check,
                label: 'Selesai',
                onPressed: _isProcessing ? null : _cropAndSave,
                isLoading: _isProcessing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: onPressed != null ? Colors.white.withOpacity(0.1) : Colors.grey[700],
            borderRadius: BorderRadius.circular(24),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: onPressed != null ? Colors.white : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      
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

        _selectedImage = file;
        await _loadImage();
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadImage() async {
    if (_selectedImage == null) return;

    final bytes = await _selectedImage!.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    setState(() {
      _decodedImage = frame.image;
      _resetCrop();
    });
  }

  void _resetCrop() {
    if (_decodedImage == null) return;
    
    setState(() {
      _scale = 1.0;
      _imageOffset = Offset.zero;
      
      // Calculate display size maintaining aspect ratio
      final imageAspect = _decodedImage!.width / _decodedImage!.height;
      final containerAspect = _containerSize.width / _containerSize.height;
      
      double displayWidth, displayHeight;
      if (imageAspect > containerAspect) {
        displayWidth = _containerSize.width;
        displayHeight = _containerSize.width / imageAspect;
      } else {
        displayHeight = _containerSize.height;
        displayWidth = _containerSize.height * imageAspect;
      }
      
      _imageDisplaySize = Size(displayWidth, displayHeight);
      
      // Set initial crop rect
      final cropSize = displayWidth * 0.6;
      final centerX = _containerSize.width / 2;
      final centerY = _containerSize.height / 2;
      
      _cropRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: cropSize,
        height: widget.aspectRatio == 1.0 ? cropSize : cropSize / widget.aspectRatio,
      );
    });
  }

  void _toggleAspectRatio() {
    setState(() {
      final center = _cropRect.center;
      final width = _cropRect.width;
      final newHeight = widget.aspectRatio == 1.0 ? width : width / widget.aspectRatio;
      
      _cropRect = Rect.fromCenter(
        center: center,
        width: width,
        height: newHeight,
      );
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastPanPosition = details.focalPoint;
    _lastScale = _scale;
    
    // Check if we're near a corner for resizing
    final corners = _getCropCorners();
    _isResizing = false;
    _resizeCorner = '';
    
    for (int i = 0; i < corners.length; i++) {
      if ((details.focalPoint - corners[i]).distance < 30) {
        _isResizing = true;
        _resizeCorner = ['tl', 'tr', 'bl', 'br'][i];
        break;
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle zoom
      if (details.scale != 1.0 && _lastScale != null && !_isResizing) {
        _scale = (_lastScale! * details.scale).clamp(0.5, 3.0);
      }
      
      // Handle pan/resize
      if (_lastPanPosition != null) {
        if (_isResizing) {
          _handleResize(details.focalPoint);
        } else {
          // Move crop area or image
          final delta = details.focalPoint - _lastPanPosition!;
          
          // If we're touching inside the crop area, move the crop area
          if (_cropRect.contains(_lastPanPosition!)) {
            _cropRect = _cropRect.translate(delta.dx, delta.dy);
            
            // Keep crop rect within bounds
            _cropRect = Rect.fromLTWH(
              _cropRect.left.clamp(0, _containerSize.width - _cropRect.width),
              _cropRect.top.clamp(0, _containerSize.height - _cropRect.height),
              _cropRect.width,
              _cropRect.height,
            );
          } else {
            // Move the image
            _imageOffset += delta;
          }
        }
        
        _lastPanPosition = details.focalPoint;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isResizing = false;
    _resizeCorner = '';
  }

  void _handleResize(Offset currentPosition) {
    final delta = currentPosition - _lastPanPosition!;
    
    switch (_resizeCorner) {
      case 'tl': // Top-left
        final newWidth = (_cropRect.width - delta.dx).clamp(50.0, _containerSize.width);
        final newHeight = widget.aspectRatio == 1.0 ? newWidth : newWidth / widget.aspectRatio;
        _cropRect = Rect.fromLTWH(
          _cropRect.right - newWidth,
          _cropRect.bottom - newHeight,
          newWidth,
          newHeight,
        );
        break;
      case 'tr': // Top-right
        final newWidth = (_cropRect.width + delta.dx).clamp(50.0, _containerSize.width);
        final newHeight = widget.aspectRatio == 1.0 ? newWidth : newWidth / widget.aspectRatio;
        _cropRect = Rect.fromLTWH(
          _cropRect.left,
          _cropRect.bottom - newHeight,
          newWidth,
          newHeight,
        );
        break;
      case 'bl': // Bottom-left
        final newWidth = (_cropRect.width - delta.dx).clamp(50.0, _containerSize.width);
        final newHeight = widget.aspectRatio == 1.0 ? newWidth : newWidth / widget.aspectRatio;
        _cropRect = Rect.fromLTWH(
          _cropRect.right - newWidth,
          _cropRect.top,
          newWidth,
          newHeight,
        );
        break;
      case 'br': // Bottom-right
        final newWidth = (_cropRect.width + delta.dx).clamp(50.0, _containerSize.width);
        final newHeight = widget.aspectRatio == 1.0 ? newWidth : newWidth / widget.aspectRatio;
        _cropRect = Rect.fromLTWH(
          _cropRect.left,
          _cropRect.top,
          newWidth,
          newHeight,
        );
        break;
    }
  }

  List<Offset> _getCropCorners() {
    return [
      _cropRect.topLeft,
      _cropRect.topRight,
      _cropRect.bottomLeft,
      _cropRect.bottomRight,
    ];
  }

  Future<void> _cropAndSave() async {
    if (_decodedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      // Calculate the actual crop area in image coordinates
      final imageRect = _getImageRect();
      final cropInImage = Rect.fromLTWH(
        (_cropRect.left - imageRect.left) / _scale,
        (_cropRect.top - imageRect.top) / _scale,
        _cropRect.width / _scale,
        _cropRect.height / _scale,
      );

      // Create a picture recorder to draw the cropped image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // Draw the cropped portion
      canvas.drawImageRect(
        _decodedImage!,
        cropInImage,
        Rect.fromLTWH(0, 0, widget.maxWidth.toDouble(), widget.maxHeight.toDouble()),
        Paint(),
      );

      // Convert to image
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(widget.maxWidth, widget.maxHeight);
      
      // Convert to bytes
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/cropped_image_${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(bytes);

      // Call the callback
      widget.onImageCropped(tempFile);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('Gagal memotong gambar: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Rect _getImageRect() {
    if (_decodedImage == null) return Rect.zero;
    
    final imageAspect = _decodedImage!.width / _decodedImage!.height;
    final containerAspect = _containerSize.width / _containerSize.height;
    
    double displayWidth, displayHeight;
    if (imageAspect > containerAspect) {
      displayWidth = _containerSize.width * _scale;
      displayHeight = _containerSize.width / imageAspect * _scale;
    } else {
      displayHeight = _containerSize.height * _scale;
      displayWidth = _containerSize.height * imageAspect * _scale;
    }
    
    final centerX = _containerSize.width / 2 + _imageOffset.dx;
    final centerY = _containerSize.height / 2 + _imageOffset.dy;
    
    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: displayWidth,
      height: displayHeight,
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
}

class ImageCropPainter extends CustomPainter {
  final ui.Image? image;
  final Rect cropRect;
  final Offset imageOffset;
  final double scale;
  final Size containerSize;

  ImageCropPainter({
    required this.image,
    required this.cropRect,
    required this.imageOffset,
    required this.scale,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    // Calculate image display rect
    final imageAspect = image!.width / image!.height;
    final containerAspect = containerSize.width / containerSize.height;
    
    double displayWidth, displayHeight;
    if (imageAspect > containerAspect) {
      displayWidth = containerSize.width * scale;
      displayHeight = containerSize.width / imageAspect * scale;
    } else {
      displayHeight = containerSize.height * scale;
      displayWidth = containerSize.height * imageAspect * scale;
    }
    
    final centerX = containerSize.width / 2 + imageOffset.dx;
    final centerY = containerSize.height / 2 + imageOffset.dy;
    
    final imageRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: displayWidth,
      height: displayHeight,
    );

    // Draw the image
    canvas.drawImageRect(
      image!,
      Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
      imageRect,
      Paint(),
    );

    // Draw overlay (darken areas outside crop)
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);
    
    // Top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, containerSize.width, cropRect.top),
      overlayPaint,
    );
    
    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.bottom, containerSize.width, containerSize.height - cropRect.bottom),
      overlayPaint,
    );
    
    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, cropRect.top, cropRect.left, cropRect.height),
      overlayPaint,
    );
    
    // Right
    canvas.drawRect(
      Rect.fromLTWH(cropRect.right, cropRect.top, containerSize.width - cropRect.right, cropRect.height),
      overlayPaint,
    );

    // Draw crop border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(cropRect, borderPaint);

    // Draw corner handles
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final corners = [
      cropRect.topLeft,
      cropRect.topRight,
      cropRect.bottomLeft,
      cropRect.bottomRight,
    ];
    
    for (final corner in corners) {
      canvas.drawCircle(corner, 8, handlePaint);
    }

    // Draw corner lines
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    for (final corner in corners) {
      if (corner == cropRect.topLeft) {
        canvas.drawLine(corner, corner + const Offset(20, 0), linePaint);
        canvas.drawLine(corner, corner + const Offset(0, 20), linePaint);
      } else if (corner == cropRect.topRight) {
        canvas.drawLine(corner, corner + const Offset(-20, 0), linePaint);
        canvas.drawLine(corner, corner + const Offset(0, 20), linePaint);
      } else if (corner == cropRect.bottomLeft) {
        canvas.drawLine(corner, corner + const Offset(20, 0), linePaint);
        canvas.drawLine(corner, corner + const Offset(0, -20), linePaint);
      } else if (corner == cropRect.bottomRight) {
        canvas.drawLine(corner, corner + const Offset(-20, 0), linePaint);
        canvas.drawLine(corner, corner + const Offset(0, -20), linePaint);
      }
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;
    
    // Vertical lines
    for (int i = 1; i < 3; i++) {
      final x = cropRect.left + (cropRect.width / 3) * i;
      canvas.drawLine(
        Offset(x, cropRect.top),
        Offset(x, cropRect.bottom),
        gridPaint,
      );
    }
    
    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = cropRect.top + (cropRect.height / 3) * i;
      canvas.drawLine(
        Offset(cropRect.left, y),
        Offset(cropRect.right, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}