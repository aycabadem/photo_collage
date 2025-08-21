import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/photo_box.dart';
import '../models/aspect_spec.dart';
import '../models/alignment_guideline.dart';
import '../utils/collage_utils.dart';

/// Service class for managing collage operations and state
class CollageManager extends ChangeNotifier {
  // Aspect ratio presets
  static const List<AspectSpec> _presets = [
    AspectSpec(w: 1, h: 1, label: '1:1'),
    AspectSpec(w: 3, h: 4, label: '3:4'),
    AspectSpec(w: 4, h: 3, label: '4:3'),
    AspectSpec(w: 4, h: 5, label: '4:5'),
    AspectSpec(w: 5, h: 4, label: '5:4'),
    AspectSpec(w: 9, h: 16, label: '9:16'),
    AspectSpec(w: 16, h: 9, label: '16:9'),
  ];

  // Template size configuration
  static const double baseWidth = 350;
  static const double minHeight = 220;

  // State variables
  AspectSpec _selectedAspect = _presets.firstWhere((a) => a.label == '9:16');
  Size _templateSize = Size(baseWidth, baseWidth);
  final List<PhotoBox> _photoBoxes = [];
  PhotoBox? _selectedBox;

  // Getters
  AspectSpec get selectedAspect => _selectedAspect;
  Size get templateSize => _templateSize;
  List<PhotoBox> get photoBoxes => List.unmodifiable(_photoBoxes);
  PhotoBox? get selectedBox => _selectedBox;
  List<AspectSpec> get presets => List.unmodifiable(_presets);

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

    // Resize and reposition boxes to fit new template size
    for (final box in _photoBoxes) {
      _adjustBoxToTemplate(box);
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

    box.position = Offset(newX, newY);
    notifyListeners();
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

  /// Get alignment guidelines for the selected photo box
  List<AlignmentGuideline> getAlignmentGuidelines(PhotoBox selectedBox) {
    try {
      final List<AlignmentGuideline> guidelines = [];

      // Show background center guidelines for ALL photos when they are actually centered
      final centerX = _templateSize.width / 2;
      final centerY = _templateSize.height / 2;

      // Check if photo is actually centered (within 3 pixels)
      final photoCenterX = selectedBox.position.dx + selectedBox.size.width / 2;
      final photoCenterY =
          selectedBox.position.dy + selectedBox.size.height / 2;

      if ((photoCenterX - centerX).abs() < 3) {
        guidelines.add(
          AlignmentGuideline(
            position: centerX,
            isHorizontal: false,
            type: 'background-center',
            label: 'Background Center',
          ),
        );
      }

      if ((photoCenterY - centerY).abs() < 3) {
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

        // Edge alignment (left, right, top, bottom) - Only show when very close
        // Left edge alignment
        if ((selectedBox.position.dx - otherBox.position.dx).abs() < 2) {
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
                .abs() <
            2) {
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
                .abs() <
            2) {
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
                .abs() <
            2) {
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
        if ((selectedBox.position.dy - otherBox.position.dy).abs() < 2) {
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
                .abs() <
            2) {
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
                .abs() <
            2) {
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
                .abs() <
            2) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy,
              isHorizontal: true,
              type: 'edge',
              label: 'Bottom to Top Edge',
            ),
          );
        }

        // Center alignment - Only show when very close
        final selectedCenterX =
            selectedBox.position.dx + selectedBox.size.width / 2;
        final otherCenterX = otherBox.position.dx + otherBox.size.width / 2;
        final selectedCenterY =
            selectedBox.position.dy + selectedBox.size.height / 2;
        final otherCenterY = otherBox.position.dy + otherBox.size.height / 2;

        if ((selectedCenterX - otherCenterX).abs() < 2) {
          guidelines.add(
            AlignmentGuideline(
              position: otherCenterX,
              isHorizontal: false,
              type: 'center',
              label: 'Center',
            ),
          );
        }

        if ((selectedCenterY - otherCenterY).abs() < 2) {
          guidelines.add(
            AlignmentGuideline(
              position: otherCenterY,
              isHorizontal: true,
              type: 'center',
              label: 'Center',
            ),
          );
        }

        // Size alignment (width and height) - Show when very close
        if ((selectedBox.size.width - otherBox.size.width).abs() < 2) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dx + otherBox.size.width / 2,
              isHorizontal: false,
              type: 'size',
              label: 'Same Width',
            ),
          );
        }

        if ((selectedBox.size.height - otherBox.size.height).abs() < 2) {
          guidelines.add(
            AlignmentGuideline(
              position: otherBox.position.dy + otherBox.size.height / 2,
              isHorizontal: true,
              type: 'size',
              label: 'Same Height',
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
