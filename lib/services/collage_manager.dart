import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/photo_box.dart';
import '../models/aspect_spec.dart';
import '../models/alignment_guideline.dart';
import '../models/layout_template.dart';
import '../utils/collage_utils.dart';

/// Service class for managing collage operations and state
class CollageManager extends ChangeNotifier {
  // Aspect ratio presets
  static const List<AspectSpec> _presets = [
    AspectSpec(w: 1.0, h: 1.0, label: '1:1'),
    AspectSpec(w: 3.0, h: 4.0, label: '3:4'),
    AspectSpec(w: 4.0, h: 3.0, label: '4:3'),
    AspectSpec(w: 4.0, h: 5.0, label: '4:5'),
    AspectSpec(w: 5.0, h: 4.0, label: '5:4'),
    AspectSpec(w: 9.0, h: 16.0, label: '9:16'),
    AspectSpec(w: 16.0, h: 9.0, label: '16:9'),
  ];

  // Template size configuration
  static const double baseWidth = 350;
  static const double minHeight = 220;

  // State variables
  AspectSpec _selectedAspect = _presets.firstWhere((a) => a.label == '9:16');
  Size _templateSize = Size(baseWidth, baseWidth);
  final List<PhotoBox> _photoBoxes = [];
  PhotoBox? _selectedBox;

  // Background color and opacity
  Color _backgroundColor = Colors.white;
  double _backgroundOpacity = 1.0;

  // Global border settings
  double _globalBorderWidth = 0.0;
  Color _globalBorderColor = Colors.black;
  bool _hasGlobalBorder = false;

  // Layout template settings
  LayoutTemplate? _currentLayout;
  bool _isCustomMode = true;

  // Getters
  AspectSpec get selectedAspect => _selectedAspect;
  Size get templateSize => _templateSize;
  List<PhotoBox> get photoBoxes => List.unmodifiable(_photoBoxes);
  PhotoBox? get selectedBox => _selectedBox;
  List<AspectSpec> get presets => List.unmodifiable(_presets);

  // Background color and opacity getters
  Color get backgroundColor => _backgroundColor;
  double get backgroundOpacity => _backgroundOpacity;

  // Global border getters
  double get globalBorderWidth => _globalBorderWidth;
  Color get globalBorderColor => _globalBorderColor;
  bool get hasGlobalBorder => _hasGlobalBorder;

  // Layout template getters
  LayoutTemplate? get currentLayout => _currentLayout;
  bool get isCustomMode => _isCustomMode;

  // Background color and opacity setters
  void changeBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void changeBackgroundOpacity(double opacity) {
    _backgroundOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  // Global border setters
  void changeGlobalBorderWidth(double width) {
    _globalBorderWidth = width.clamp(0.0, 10.0);
    _hasGlobalBorder = _globalBorderWidth > 0.0;
    notifyListeners();
  }

  void changeGlobalBorderColor(Color color) {
    _globalBorderColor = color;
    notifyListeners();
  }

  // Layout template setters
  void applyLayoutTemplate(LayoutTemplate? layout) {
    if (layout == null) {
      // Custom mode - clear current layout
      _currentLayout = null;
      _isCustomMode = true;
      _photoBoxes.clear();
      notifyListeners();
      return;
    }

    // Apply preset layout
    _currentLayout = layout;
    _isCustomMode = false;

    // Clear existing photo boxes
    _photoBoxes.clear();

    // Get scaled layouts for current aspect ratio
    final scaledLayouts = layout.getScaledLayouts(
      _selectedAspect.w / _selectedAspect.h,
    );

    // Create photo boxes based on layout
    for (int i = 0; i < scaledLayouts.length; i++) {
      final photoLayout = scaledLayouts[i];

      // Calculate actual positions and sizes based on template size
      final actualPosition = Offset(
        photoLayout.position.dx * _templateSize.width,
        photoLayout.position.dy * _templateSize.height,
      );

      final actualSize = Size(
        photoLayout.size.width * _templateSize.width,
        photoLayout.size.height * _templateSize.height,
      );

      // Create placeholder photo box
      final photoBox = PhotoBox(
        position: actualPosition,
        size: actualSize,
        imagePath: '', // Empty for placeholder
      );

      _photoBoxes.add(photoBox);
    }

    // Clear selection
    _selectedBox = null;

    // Auto-enable border for layout templates
    if (!_hasGlobalBorder) {
      _globalBorderWidth = 2.0;
      _globalBorderColor = Colors.grey[400]!;
      _hasGlobalBorder = true;
    }

    notifyListeners();
  }

  /// Update layout when aspect ratio changes
  void _updateLayoutForAspectRatio() {
    if (_currentLayout != null && !_isCustomMode) {
      // Re-apply layout with new aspect ratio
      applyLayoutTemplate(_currentLayout);
    }
  }

  // Get background color with opacity
  Color get backgroundColorWithOpacity =>
      _backgroundColor.withValues(alpha: _backgroundOpacity);

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  /// Calculate template size based on aspect ratio and screen size
  Size _sizeForAspect(AspectSpec a, {Size? screenSize}) {
    // Default sizes
    double maxWidth = baseWidth;
    double maxHeight = baseWidth;

    if (screenSize != null) {
      // Optimize spacing - minimal margin for maximum screen usage
      double availableWidth = screenSize.width - 40; // Reduced from 60
      double availableHeight = screenSize.height - 80; // Reduced from 120

      // More generous limits for better visual appeal
      maxWidth = availableWidth.clamp(350, 520.0); // Increased from 320-480
      maxHeight = availableHeight.clamp(300, 600.0); // Increased from 280-550
    }

    // Size strategy based on aspect ratio type
    double aspectRatio = a.ratio;
    double width, height;

    if (aspectRatio > 2) {
      // Very wide ratios (10:1, 16:1 etc.)
      width = maxWidth * 0.99; // Increased from 0.98
      height = width / aspectRatio;

      if (height < 120) {
        // Increased from 100
        height = 120;
        width = height * aspectRatio;
        if (width > maxWidth * 0.99) {
          width = maxWidth * 0.99;
          height = width / aspectRatio;
        }
      }
    } else if (aspectRatio < 0.5) {
      // Very tall ratios (9:16, 1:6 etc.)
      width = maxWidth * 0.85; // Increased from 0.8
      height = width / aspectRatio;
      if (height > maxHeight * 0.99) {
        // Increased from 0.98
        height = maxHeight * 0.99;
        width = height * aspectRatio;
      }
    } else if (aspectRatio >= 0.8 && aspectRatio <= 1.25) {
      // Medium ratios (4:5, 5:4, 1:1, 3:4, 4:3)
      if (aspectRatio >= 1) {
        width = maxWidth * 0.96; // Increased from 0.92
        height = width / aspectRatio;
        if (height > maxHeight * 0.92) {
          // Increased from 0.85
          height = maxHeight * 0.92;
          width = height * aspectRatio;
        }
      } else {
        height = maxHeight * 0.92; // Increased from 0.85
        width = height * aspectRatio;
        if (width > maxWidth * 0.96) {
          // Increased from 0.92
          width = maxWidth * 0.96;
          height = width / aspectRatio;
        }
      }
    } else {
      // Other ratios
      if (aspectRatio >= 1) {
        width = maxWidth * 0.98; // Increased from 0.95
        height = width / aspectRatio;
        if (height > maxHeight * 0.95) {
          // Increased from 0.9
          height = maxHeight * 0.95;
          width = height * aspectRatio;
        }
      } else {
        height = maxHeight * 0.95; // Increased from 0.9
        width = height * aspectRatio;
        if (width > maxWidth * 0.98) {
          // Increased from 0.95
          width = maxWidth * 0.98;
          height = width / aspectRatio;
        }
      }
    }

    // Minimum size control - increased for better visibility
    if (width < 250) width = 250; // Increased from 200
    if (height < 180) height = 180; // Increased from 150

    // Maximum size control - more generous
    if (width > maxWidth * 0.99) {
      width = maxWidth * 0.99; // Increased from 0.98
    }
    if (height > maxHeight * 0.99) {
      height = maxHeight * 0.99; // Increased from 0.98
    }

    return Size(width, height);
  }

  /// Apply new aspect ratio and resize existing boxes
  void applyAspect(AspectSpec newAspect, {Size? screenSize}) {
    if (newAspect.w <= 0 || newAspect.h <= 0) return;

    _selectedAspect = newAspect;
    _templateSize = _sizeForAspect(newAspect, screenSize: screenSize);

    // If using preset layout, re-apply it with new aspect ratio
    if (_currentLayout != null && !_isCustomMode) {
      _updateLayoutForAspectRatio();
    } else {
      // Custom mode - resize and reposition existing boxes
      for (final box in _photoBoxes) {
        _adjustBoxToTemplate(box);
      }
    }

    notifyListeners();
  }

  /// Adjust a photo box to fit within the current template
  void _adjustBoxToTemplate(PhotoBox box) {
    double newWidth = box.size.width;
    double newHeight = box.size.height;

    // Shrink box if it's larger than template
    if (newWidth > _templateSize.width - 40) {
      newWidth = _templateSize.width - 40;
    }
    if (newHeight > _templateSize.height - 40) {
      newHeight = _templateSize.height - 40;
    }

    // Minimum size control
    if (newWidth < 50) newWidth = 50;
    if (newHeight < 50) newHeight = 50;

    // Update size
    box.size = Size(newWidth, newHeight);

    // Adjust position
    double newX = box.position.dx;
    double newY = box.position.dy;

    if (newX < 0) newX = 0;
    if (newY < 0) newY = 0;
    if (newX + newWidth > _templateSize.width) {
      newX = _templateSize.width - newWidth;
    }
    if (newY + newHeight > _templateSize.height) {
      newY = _templateSize.height - newHeight;
    }

    box.position = Offset(newX, newY);
  }

  /// Select a photo box
  void selectBox(PhotoBox? box) {
    _selectedBox = box;
    notifyListeners();
  }

  /// Add a new photo box
  Future<void> addPhotoBox() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      Size boxSize = const Size(150, 150);
      Offset pos = CollageUtils.findNonOverlappingPosition(
        _photoBoxes,
        _templateSize,
        boxSize,
      );

      var newBox = PhotoBox(
        position: pos,
        size: boxSize,
        imageFile: File(pickedFile.path),
        imagePath: pickedFile.path,
      );

      _photoBoxes.add(newBox);
      _selectedBox = newBox;
      notifyListeners();
    }
  }

  /// Add photo to a specific existing box
  Future<void> addPhotoToBox(PhotoBox targetBox) async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Update the target box with the selected image
      targetBox.imageFile = File(pickedFile.path);
      targetBox.imagePath = pickedFile.path;

      // Select this box
      _selectedBox = targetBox;
      notifyListeners();
    }
  }

  /// Delete a photo box
  void deleteBox(PhotoBox box) {
    _photoBoxes.remove(box);
    if (_selectedBox == box) {
      _selectedBox = null;
    }
    notifyListeners();
  }

  /// Move a photo box
  void moveBox(PhotoBox box, Offset delta) {
    double newX = CollageUtils.safeClamp(
      box.position.dx + delta.dx,
      0.0,
      _templateSize.width - box.size.width,
    );
    double newY = CollageUtils.safeClamp(
      box.position.dy + delta.dy,
      0.0,
      _templateSize.height - box.size.height,
    );

    // Apply snapping to other photo boxes
    final snappedPosition = _applySnapping(Offset(newX, newY), box);

    box.position = snappedPosition;
    notifyListeners();
  }

  /// Apply snapping to align with other photo boxes
  Offset _applySnapping(Offset position, PhotoBox movingBox) {
    double snappedX = position.dx;
    double snappedY = position.dy;

    for (final otherBox in _photoBoxes) {
      if (otherBox == movingBox) continue;

      // 1. Edge-to-edge snapping (same edges align)
      // Left edge to left edge
      if ((position.dx - otherBox.position.dx).abs() <= 5) {
        snappedX = otherBox.position.dx;
      }

      // Right edge to right edge
      if ((position.dx +
                  movingBox.size.width -
                  otherBox.position.dx -
                  otherBox.size.width)
              .abs() <=
          5) {
        snappedX =
            otherBox.position.dx + otherBox.size.width - movingBox.size.width;
      }

      // Top edge to top edge
      if ((position.dy - otherBox.position.dy).abs() <= 5) {
        snappedY = otherBox.position.dy;
      }

      // Bottom edge to bottom edge
      if ((position.dy +
                  movingBox.size.height -
                  otherBox.position.dy -
                  otherBox.size.height)
              .abs() <=
          5) {
        snappedY =
            otherBox.position.dy + otherBox.size.height - movingBox.size.height;
      }

      // 2. Edge-to-edge snapping (adjacent placement)
      // Left edge to right edge (place moving box to the right)
      if ((position.dx - (otherBox.position.dx + otherBox.size.width)).abs() <=
          5) {
        snappedX = otherBox.position.dx + otherBox.size.width;
      }

      // Right edge to left edge (place moving box to the left)
      if ((position.dx + movingBox.size.width - otherBox.position.dx).abs() <=
          5) {
        snappedX = otherBox.position.dx - movingBox.size.width;
      }

      // Top edge to bottom edge (place moving box below)
      if ((position.dy - (otherBox.position.dy + otherBox.size.height)).abs() <=
          5) {
        snappedY = otherBox.position.dy + otherBox.size.height;
      }

      // Bottom edge to top edge (place moving box above)
      if ((position.dy + movingBox.size.height - otherBox.position.dy).abs() <=
          5) {
        snappedY = otherBox.position.dy - movingBox.size.height;
      }

      // 3. Center snapping
      final movingCenterX = position.dx + movingBox.size.width / 2;
      final otherCenterX = otherBox.position.dx + otherBox.size.width / 2;
      if ((movingCenterX - otherCenterX).abs() <= 5) {
        snappedX = otherCenterX - movingBox.size.width / 2;
      }

      final movingCenterY = position.dy + movingBox.size.height / 2;
      final otherCenterY = otherBox.position.dy + otherBox.size.height / 2;
      if ((movingCenterY - otherCenterY).abs() <= 5) {
        snappedY = otherCenterY - movingBox.size.height / 2;
      }

      // 4. Corner-to-corner snapping
      // Top-left corner to bottom-right corner
      if ((position.dx - (otherBox.position.dx + otherBox.size.width)).abs() <=
              5 &&
          (position.dy - (otherBox.position.dy + otherBox.size.height)).abs() <=
              5) {
        snappedX = otherBox.position.dx + otherBox.size.width;
        snappedY = otherBox.position.dy + otherBox.size.height;
      }

      // Top-right corner to bottom-left corner
      if ((position.dx + movingBox.size.width - otherBox.position.dx).abs() <=
              5 &&
          (position.dy - (otherBox.position.dy + otherBox.size.height)).abs() <=
              5) {
        snappedX = otherBox.position.dx - movingBox.size.width;
        snappedY = otherBox.position.dy + otherBox.size.height;
      }

      // Bottom-left corner to top-right corner
      if ((position.dx - (otherBox.position.dx + otherBox.size.width)).abs() <=
              5 &&
          (position.dy + movingBox.size.height - otherBox.position.dy).abs() <=
              5) {
        snappedX = otherBox.position.dx + otherBox.size.width;
        snappedY = otherBox.position.dy - movingBox.size.height;
      }

      // Bottom-right corner to top-left corner
      if ((position.dx + movingBox.size.width - otherBox.position.dx).abs() <=
              5 &&
          (position.dy + movingBox.size.height - otherBox.position.dy).abs() <=
              5) {
        snappedX = otherBox.position.dx - movingBox.size.width;
        snappedY = otherBox.position.dy - movingBox.size.height;
      }
    }

    // 5. Background center snapping
    final centerX = _templateSize.width / 2;
    final centerY = _templateSize.height / 2;
    final movingCenterX = position.dx + movingBox.size.width / 2;
    final movingCenterY = position.dy + movingBox.size.height / 2;

    if ((movingCenterX - centerX).abs() <= 5) {
      snappedX = centerX - movingBox.size.width / 2;
    }
    if ((movingCenterY - centerY).abs() <= 5) {
      snappedY = centerY - movingBox.size.height / 2;
    }

    return Offset(snappedX, snappedY);
  }

  /// Resize a photo box
  void resizeBox(PhotoBox box, double deltaWidth, double deltaHeight) {
    // Calculate new dimensions
    double newWidth = CollageUtils.safeClamp(
      box.size.width + deltaWidth,
      50.0,
      _templateSize.width - box.position.dx,
    );
    double newHeight = CollageUtils.safeClamp(
      box.size.height + deltaHeight,
      50.0,
      _templateSize.height - box.position.dy,
    );

    if (newWidth >= 50 && newHeight >= 50) {
      // Update size
      box.size = Size(newWidth, newHeight);
      notifyListeners();
    }
  }

  /// Resize a photo box from a specific handle
  void resizeBoxFromHandle(
    PhotoBox box,
    Alignment handleAlignment,
    double deltaWidth,
    double deltaHeight,
  ) {
    double newWidth = box.size.width;
    double newHeight = box.size.height;
    double newX = box.position.dx;
    double newY = box.position.dy;

    // Apply changes based on handle position
    if (handleAlignment == Alignment.topLeft) {
      // Top-left: adjust width and height, move position
      newWidth = CollageUtils.safeClamp(
        box.size.width - deltaWidth,
        50.0,
        box.position.dx + box.size.width,
      );
      newHeight = CollageUtils.safeClamp(
        box.size.height - deltaHeight,
        50.0,
        box.position.dy + box.size.height,
      );
      newX = box.position.dx + (box.size.width - newWidth);
      newY = box.position.dy + (box.size.height - newHeight);
    } else if (handleAlignment == Alignment.topRight) {
      // Top-right: adjust width and height, move Y position
      newWidth = CollageUtils.safeClamp(
        box.size.width + deltaWidth,
        50.0,
        _templateSize.width - box.position.dx,
      );
      newHeight = CollageUtils.safeClamp(
        box.size.height - deltaHeight,
        50.0,
        box.position.dy + box.size.height,
      );
      newY = box.position.dy + (box.size.height - newHeight);
    } else if (handleAlignment == Alignment.bottomLeft) {
      // Bottom-left: adjust width and height, move X position
      newWidth = CollageUtils.safeClamp(
        box.size.width - deltaWidth,
        50.0,
        box.position.dx + box.size.width,
      );
      newHeight = CollageUtils.safeClamp(
        box.size.height + deltaHeight,
        50.0,
        _templateSize.height - box.position.dy,
      );
      newX = box.position.dx + (box.size.width - newWidth);
    } else if (handleAlignment == Alignment.bottomRight) {
      // Bottom-right: adjust width and height, keep position
      newWidth = CollageUtils.safeClamp(
        box.size.width + deltaWidth,
        50.0,
        _templateSize.width - box.position.dx,
      );
      newHeight = CollageUtils.safeClamp(
        box.size.height + deltaHeight,
        50.0,
        _templateSize.height - box.position.dy,
      );
    }

    // Apply changes if valid
    if (newWidth >= 50 && newHeight >= 50) {
      box.size = Size(newWidth, newHeight);
      box.position = Offset(newX, newY);
      notifyListeners();
    }
  }

  /// Initialize template size based on screen size
  void initializeTemplateSize(Size screenSize) {
    final newSize = _sizeForAspect(_selectedAspect, screenSize: screenSize);
    if (_templateSize != newSize) {
      _templateSize = newSize;
      notifyListeners();
    }
  }

  /// Save the current collage as an image
  Future<bool> saveCollage() async {
    try {
      // Create a high-quality image with the selected aspect ratio
      final double aspectRatio = _selectedAspect.ratio;
      final int targetWidth = 1200; // High quality base width
      final int targetHeight = (targetWidth / aspectRatio).round();

      // Create a custom painter for the collage
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Set background color
      final paint = Paint()..color = const Color(0xFFF5F5F5); // Light grey
      canvas.drawRect(
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        paint,
      );

      // Draw photo boxes with proper scaling
      final double scaleX = targetWidth / _templateSize.width;
      final double scaleY = targetHeight / _templateSize.height;

      for (final box in _photoBoxes) {
        if (box.imageFile != null && box.imageFile!.existsSync()) {
          try {
            final image = await _loadImage(box.imageFile!);
            if (image != null) {
              final scaledPosition = Offset(
                box.position.dx * scaleX,
                box.position.dy * scaleY,
              );
              final scaledSize = Size(
                box.size.width * scaleX,
                box.size.height * scaleY,
              );

              // Draw the image with proper scaling and positioning
              final srcRect = Rect.fromLTWH(
                0,
                0,
                image.width.toDouble(),
                image.height.toDouble(),
              );
              final dstRect = Rect.fromLTWH(
                scaledPosition.dx,
                scaledPosition.dy,
                scaledSize.width,
                scaledSize.height,
              );

              canvas.drawImageRect(image, srcRect, dstRect, Paint());

              // Draw borders if enabled
              if (_hasGlobalBorder && _globalBorderWidth > 0) {
                _drawSimpleBorders(
                  canvas,
                  scaledPosition,
                  scaledSize,
                  scaleX,
                  scaleY,
                );
              }
            }
          } catch (e) {
            // Error loading image - skip this image
          }
        }
      }

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(targetWidth, targetHeight);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        // Save to gallery
        final result = await ImageGallerySaver.saveImage(
          byteData.buffer.asUint8List(),
          quality: 100,
          name: 'collage_${DateTime.now().millisecondsSinceEpoch}',
        );

        return result['isSuccess'] == true;
      }

      return false;
    } catch (e) {
      // Error saving collage - return false
      return false;
    }
  }

  /// Load image from file
  Future<ui.Image?> _loadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      // Error loading image - return null
      return null;
    }
  }

  /// Draw simple borders for save collage (all edges)
  void _drawSimpleBorders(
    Canvas canvas,
    Offset position,
    Size size,
    double scaleX,
    double scaleY,
  ) {
    final paint = Paint()
      ..color = _globalBorderColor
      ..strokeWidth =
          _globalBorderWidth *
          scaleX // Scale border width
      ..style = PaintingStyle.stroke;

    // Draw borders on ALL edges (simple approach)
    // Left border
    canvas.drawLine(
      Offset(position.dx, position.dy),
      Offset(position.dx, position.dy + size.height),
      paint,
    );

    // Right border
    canvas.drawLine(
      Offset(position.dx + size.width, position.dy),
      Offset(position.dx + size.width, position.dy + size.height),
      paint,
    );

    // Top border
    canvas.drawLine(
      Offset(position.dx, position.dy),
      Offset(position.dx + size.width, position.dy),
      paint,
    );

    // Bottom border
    canvas.drawLine(
      Offset(position.dx, position.dy + size.height),
      Offset(position.dx + size.width, position.dy + size.height),
      paint,
    );
  }

  /// Get alignment guidelines for the selected photo box
  List<AlignmentGuideline> getAlignmentGuidelines(PhotoBox selectedBox) {
    try {
      final List<AlignmentGuideline> guidelines = [];

      // Show background center guidelines for ALL photos when they are actually centered
      final centerX = _templateSize.width / 2;
      final centerY = _templateSize.height / 2;

      // Check if photo is actually centered (exact pixel match)
      final photoCenterX = selectedBox.position.dx + selectedBox.size.width / 2;
      final photoCenterY =
          selectedBox.position.dy + selectedBox.size.height / 2;

      if ((photoCenterX - centerX).abs() <= 5) {
        guidelines.add(
          AlignmentGuideline(
            position: centerX,
            isHorizontal: false,
            type: 'background-center',
            label: 'Background Center',
          ),
        );
      }

      if ((photoCenterY - centerY).abs() <= 5) {
        guidelines.add(
          AlignmentGuideline(
            position: centerY,
            isHorizontal: true,
            type: 'background-center',
            label: 'Background Center',
          ),
        );
      }

      // Only show other guidelines when there are other photo boxes
      if (_photoBoxes.length <= 1) {
        return guidelines;
      }

      // Check alignment with other photo boxes
      for (final otherBox in _photoBoxes) {
        if (otherBox == selectedBox) continue;

        // Edge alignment (left, right, top, bottom) - Only show when exactly aligned
        // Left edge alignment
        if ((selectedBox.position.dx - otherBox.position.dx).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'edge',
              label: 'Left Edge',
            ),
          );
        }

        // Right edge alignment
        if ((selectedBox.position.dx +
                    selectedBox.size.width -
                    otherBox.position.dx -
                    otherBox.size.width)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'edge',
              label: 'Right Edge',
            ),
          );
        }

        // Left edge to right edge alignment
        if ((selectedBox.position.dx -
                    (otherBox.position.dx + otherBox.size.width))
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'edge',
              label: 'Left to Right Edge',
            ),
          );
        }

        // Right edge to left edge alignment
        if (((selectedBox.position.dx + selectedBox.size.width) -
                    otherBox.position.dx)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'edge',
              label: 'Right to Left Edge',
            ),
          );
        }

        // Top edge alignment
        if ((selectedBox.position.dy - otherBox.position.dy).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'edge',
              label: 'Top Edge',
            ),
          );
        }

        // Bottom edge alignment
        if ((selectedBox.position.dy +
                    selectedBox.size.height -
                    otherBox.position.dy -
                    otherBox.size.height)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'edge',
              label: 'Bottom Edge',
            ),
          );
        }

        // Top edge to bottom edge alignment
        if ((selectedBox.position.dy -
                    (otherBox.position.dy + otherBox.size.height))
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'edge',
              label: 'Top to Bottom Edge',
            ),
          );
        }

        // Bottom edge to top edge alignment
        if (((selectedBox.position.dy + selectedBox.size.height) -
                    otherBox.position.dy)
                .abs() <=
            5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'edge',
              label: 'Bottom to Top Edge',
            ),
          );
        }

        // Center alignment - Only show when exactly aligned
        final selectedCenterX =
            selectedBox.position.dx + selectedBox.size.width / 2;
        final otherCenterX = otherBox.position.dx + otherBox.size.width / 2;
        final selectedCenterY =
            selectedBox.position.dy + selectedBox.size.height / 2;
        final otherCenterY = otherBox.position.dy + otherBox.size.height / 2;

        if ((selectedCenterX - otherCenterX).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherCenterX,
              isHorizontal: false,
              type: 'center',
              label: 'Center',
            ),
          );
        }

        if ((selectedCenterY - otherCenterY).abs() <= 5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherCenterY,
              isHorizontal: true,
              type: 'center',
              label: 'Center',
            ),
          );
        }

        // Corner-to-corner alignment guidelines
        // Top-left corner to bottom-right corner
        if ((selectedBox.position.dx -
                        (otherBox.position.dx + otherBox.size.width))
                    .abs() <=
                5 &&
            (selectedBox.position.dy -
                        (otherBox.position.dy + otherBox.size.height))
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }

        // Top-right corner to bottom-left corner
        if (((selectedBox.position.dx + selectedBox.size.width) -
                        otherBox.position.dx)
                    .abs() <=
                5 &&
            (selectedBox.position.dy -
                        (otherBox.position.dy + otherBox.size.height))
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }

        // Bottom-left corner to top-right corner
        if ((selectedBox.position.dx -
                        (otherBox.position.dx + otherBox.size.width))
                    .abs() <=
                5 &&
            ((selectedBox.position.dy + selectedBox.size.height) -
                        otherBox.position.dy)
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }

        // Bottom-right corner to top-left corner
        if (((selectedBox.position.dx + selectedBox.size.width) -
                        otherBox.position.dx)
                    .abs() <=
                5 &&
            ((selectedBox.position.dy + selectedBox.size.height) -
                        otherBox.position.dy)
                    .abs() <=
                5) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx,
              isHorizontal: false,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'corner',
              label: 'Corner Alignment',
            ),
          );
        }
      }

      return guidelines;
    } catch (e) {
      // Error getting guidelines - return empty list
      return [];
    }
  }
}
