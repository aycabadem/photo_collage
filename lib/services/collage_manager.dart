import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/background.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import '../models/photo_box.dart';
import '../models/aspect_spec.dart';
import '../models/alignment_guideline.dart';
import '../models/layout_template.dart';
import '../utils/collage_utils.dart';

/// Snapshot of custom layout for aspect ratio transitions
class CustomLayoutSnapshot {
  final List<PhotoLayout> photoLayouts;
  final AspectSpec originalAspect;
  final Map<int, String> photoPathsMap; // Store photo paths by index
  final Map<int, BoxFit> photoFitsMap; // Store photo fits by index

  CustomLayoutSnapshot({
    required this.photoLayouts,
    required this.originalAspect,
    required this.photoPathsMap,
    required this.photoFitsMap,
  });
}

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
  Size? _availableArea; // last known canvas available area from LayoutBuilder
  final List<PhotoBox> _photoBoxes = [];
  PhotoBox? _selectedBox;

  // Background color and opacity
  Color _backgroundColor = Colors.white;
  double _backgroundOpacity = 1.0;
  BackgroundMode _backgroundMode = BackgroundMode.solid;
  GradientSpec _backgroundGradient = GradientSpec.presetPinkPurple();

  // Global border settings
  double _globalBorderWidth = 0.0; // Start with 0 margin
  Color _globalBorderColor =
      Colors.white; // Changed back to white so border is visible
  bool _hasGlobalBorder = false;

  // Photo margin settings (separate from border)
  double _photoMargin = 0.0; // New property for photo spacing

  // New border effect properties
  double _shadowIntensity = 0.0;
  double _innerMargin = 0.0;
  double _outerMargin = 0.0;
  double _cornerRadius = 0.0;

  // Layout template settings
  LayoutTemplate? _currentLayout;
  bool _isCustomMode = true;

  // Custom layout snapshot for aspect ratio transitions
  CustomLayoutSnapshot? _customLayoutSnapshot;

  // Getters
  AspectSpec get selectedAspect => _selectedAspect;
  Size get templateSize => _templateSize;
  List<PhotoBox> get photoBoxes => List.unmodifiable(_photoBoxes);
  PhotoBox? get selectedBox => _selectedBox;
  List<AspectSpec> get presets => List.unmodifiable(_presets);

  // Background color and opacity getters
  Color get backgroundColor => _backgroundColor;
  double get backgroundOpacity => _backgroundOpacity;
  BackgroundMode get backgroundMode => _backgroundMode;
  GradientSpec get backgroundGradient => _backgroundGradient;

  // Border getters
  bool get hasGlobalBorder => _hasGlobalBorder;
  double get globalBorderWidth => _globalBorderWidth;
  Color get globalBorderColor => _globalBorderColor;

  // New border effect getters
  double get shadowIntensity => _shadowIntensity;
  double get innerMargin => _innerMargin;
  double get outerMargin => _outerMargin;
  double get cornerRadius => _cornerRadius;

  // Layout template getters
  LayoutTemplate? get currentLayout => _currentLayout;
  bool get isCustomMode => _isCustomMode;

  // Photo margin getter and setter
  double get photoMargin => _photoMargin;

  void setPhotoMargin(double margin) {
    _photoMargin = margin.clamp(0.0, 15.0); // Reduced max to 15px
    notifyListeners();
  }

  // Background color and opacity setters
  void changeBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void changeBackgroundOpacity(double opacity) {
    _backgroundOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setBackgroundMode(BackgroundMode mode) {
    _backgroundMode = mode;
    notifyListeners();
  }

  void setBackgroundGradient(GradientSpec spec) {
    _backgroundGradient = spec;
    _backgroundMode = BackgroundMode.gradient;
    notifyListeners();
  }

  List<Color> get gradientColorsWithOpacity {
    return _backgroundGradient.stops
        .map((s) => s.color.withValues(alpha: s.color.a * _backgroundOpacity))
        .toList();
  }

  List<double> get gradientStops =>
      _backgroundGradient.stops.map((s) => s.offset).toList();

  // Global border setters
  /// Change global border width (used for margin)
  void changeGlobalBorderWidth(double width) {
    _globalBorderWidth = width.clamp(0.0, 50.0); // Fixed: allow 0-50px range
    _hasGlobalBorder = _globalBorderWidth > 0.0;
    notifyListeners();
  }

  void changeGlobalBorderColor(Color color) {
    _globalBorderColor = color;
    notifyListeners();
  }

  /// Set shadow intensity
  void setShadowIntensity(double intensity) {
    _shadowIntensity = intensity.clamp(0.0, 14.0);
    notifyListeners();
  }

  /// Set inner margin
  void setInnerMargin(double margin) {
    _innerMargin = margin;
    notifyListeners();
  }

  /// Set outer margin
  void setOuterMargin(double margin) {
    _outerMargin = margin;
    notifyListeners();
  }

  /// Set corner radius
  void setCornerRadius(double radius) {
    _cornerRadius = radius.clamp(0.0, 40.0); // Reduced max to 40px
    notifyListeners();
  }

  /// Public method to trigger UI updates safely from widgets
  void refresh() {
    notifyListeners();
  }

  // Layout template setters
  void applyLayoutTemplate(LayoutTemplate? layout) {
    if (layout == null) {
      // Custom mode - clear current layout
      _currentLayout = null;
      _isCustomMode = true;
      _photoBoxes.clear();
      // In custom mode, default to no margin for free placement
      _photoMargin = 0.0;
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

    // Create photo boxes based on layout (use the actual photoLayouts count)
    for (int i = 0; i < layout.photoLayouts.length; i++) {
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

      // Debug logs removed

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

    // For preset grid layouts, start with a tiny margin so grid is visible
    // Users can still adjust via the panel afterward
    _photoMargin = 1.0; // ~1px default spacing for templates

    // Auto-enable border for layout templates - REMOVED to start without margin
    // if (!_hasGlobalBorder) {
    //   _globalBorderWidth = 2.0;
    //   _globalBorderColor = Colors.grey[400]!;
    //   _hasGlobalBorder = true;
    // }

    notifyListeners();
  }

  /// Update layout when aspect ratio changes
  void _updateLayoutForAspectRatio() {
    if (_currentLayout != null && !_isCustomMode) {
      // Preserve existing photos but update positions and sizes
      final existingPhotos = Map<int, PhotoBox>.fromEntries(
        _photoBoxes.asMap().entries,
      );

      // Clear and recreate boxes with new template size
      _photoBoxes.clear();

      // Get scaled layouts for current aspect ratio
      final scaledLayouts = _currentLayout!.getScaledLayouts(
        _selectedAspect.w / _selectedAspect.h,
      );

      // Create photo boxes based on layout, preserving existing photos
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

        // Check if we have an existing photo for this position
        PhotoBox photoBox;
        if (existingPhotos.containsKey(i) &&
            existingPhotos[i]!.imageFile != null) {
          // Preserve existing photo with new position and size
          photoBox = PhotoBox(
            position: actualPosition,
            size: actualSize,
            imageFile: existingPhotos[i]!.imageFile,
            imagePath: existingPhotos[i]!.imagePath,
            imageFit: existingPhotos[i]!.imageFit,
          );
        } else {
          // Create placeholder photo box
          photoBox = PhotoBox(
            position: actualPosition,
            size: actualSize,
            imagePath: '', // Empty for placeholder
          );
        }

        _photoBoxes.add(photoBox);
      }

      // Clear selection
      _selectedBox = null;

      notifyListeners();
    }
  }

  // Get background color with opacity
  Color get backgroundColorWithOpacity =>
      _backgroundColor.withValues(alpha: _backgroundOpacity);

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  /// Calculate template size based on aspect ratio and available area
  /// screenSize here represents the available canvas area (constraints), not full screen
  Size _sizeForAspect(AspectSpec a, {Size? screenSize}) {
    // Available area
    double availW = baseWidth;
    double availH = baseWidth;
    if (screenSize != null) {
      // Use constraints, but leave a tasteful frame so canvas isn't full-bleed
      const double sideMargin = 40.0;   // left+right total
      const double vertMargin = 80.0;   // top+bottom total

      availW = screenSize.width - sideMargin;
      availH = screenSize.height - vertMargin;

      // Keep reasonable lower bounds
      if (availW < 260) availW = 260;
      if (availH < 220) availH = 220;
    }

    final double r = a.ratio; // width / height

    // Contain-fit without branchy clamps: exactly one side touches bound
    double width, height;
    if (availH * r <= availW) {
      // Height-bound
      height = availH;
      width = height * r;
    } else {
      // Width-bound
      width = availW;
      height = width / r;
    }

    // Enforce gentle minimums by uniform scaling up, but never exceed bounds
    const double minW = 250.0;
    const double minH = 180.0;
    final double scaleUp = math.max(
      math.max(minW / width, minH / height),
      1.0,
    );
    if (scaleUp > 1.0) {
      final double maxScale = math.min(availW / width, availH / height);
      final double s = math.min(scaleUp, maxScale);
      width *= s;
      height *= s;
    }

    return Size(width, height);
  }

  /// Apply new aspect ratio and resize existing boxes
  void applyAspect(AspectSpec newAspect, {Size? screenSize}) {
    if (newAspect.w <= 0 || newAspect.h <= 0) return;

    _selectedAspect = newAspect;
    // Prefer last known available area from LayoutBuilder
    final area = _availableArea ?? screenSize;
    _templateSize = _sizeForAspect(newAspect, screenSize: area);

    // If using preset layout, re-apply it with new aspect ratio
    if (_currentLayout != null && !_isCustomMode) {
      _updateLayoutForAspectRatio();
    } else {
      // Custom mode - use layout snapshot approach
      if (_photoBoxes.isNotEmpty) {
        // Create snapshot before changing aspect ratio
        _createCustomLayoutSnapshot();
        // Apply snapshot to new aspect ratio (like preset layouts)
        _applyCustomLayoutSnapshot(newAspect);
      }
    }

    notifyListeners();
  }

  /// Create a snapshot of current custom layout
  void _createCustomLayoutSnapshot() {
    if (!_isCustomMode || _photoBoxes.isEmpty) return;

    final photoLayouts = <PhotoLayout>[];
    final photoPathsMap = <int, String>{};
    final photoFitsMap = <int, BoxFit>{};

    for (int i = 0; i < _photoBoxes.length; i++) {
      final box = _photoBoxes[i];

      // Normalize position and size (0-1 range)
      final normalizedX = box.position.dx / _templateSize.width;
      final normalizedY = box.position.dy / _templateSize.height;
      final normalizedWidth = box.size.width / _templateSize.width;
      final normalizedHeight = box.size.height / _templateSize.height;

      // Create PhotoLayout (like preset layouts)
      photoLayouts.add(
        PhotoLayout(
          position: Offset(normalizedX, normalizedY),
          size: Size(normalizedWidth, normalizedHeight),
        ),
      );

      // Store photo data
      if (box.imageFile != null &&
          box.imagePath != null &&
          box.imagePath!.isNotEmpty) {
        photoPathsMap[i] = box.imagePath!;
        photoFitsMap[i] = box.imageFit;
      }
    }

    // Save snapshot
    _customLayoutSnapshot = CustomLayoutSnapshot(
      photoLayouts: photoLayouts,
      originalAspect: _selectedAspect,
      photoPathsMap: photoPathsMap,
      photoFitsMap: photoFitsMap,
    );
  }

  /// Apply custom layout snapshot to new aspect ratio
  void _applyCustomLayoutSnapshot(AspectSpec newAspect) {
    if (_customLayoutSnapshot == null) return;

    // Clear current boxes
    _photoBoxes.clear();

    // Get scaled layouts for new aspect ratio (like preset layouts do)
    final scaledLayouts = _customLayoutSnapshot!.photoLayouts.map((layout) {
      return PhotoLayout(
        position: layout.position, // Already normalized 0-1
        size: layout.size, // Already normalized 0-1
      );
    }).toList();

    // Calculate template coverage to determine stretch factors
    double maxX = 0, maxY = 0;
    for (final layout in scaledLayouts) {
      final rightEdge = layout.position.dx + layout.size.width;
      final bottomEdge = layout.position.dy + layout.size.height;
      if (rightEdge > maxX) maxX = rightEdge;
      if (bottomEdge > maxY) maxY = bottomEdge;
    }

    // Calculate stretch factors for both dimensions
    double stretchX = maxX < 0.95 ? 0.95 / maxX : 1.0;
    double stretchY = maxY < 0.95 ? 0.95 / maxY : 1.0;

    // Use the larger stretch factor to fill template better
    double stretchFactor = stretchX > stretchY ? stretchX : stretchY;

    // Create photo boxes with new template size (exactly like preset layouts)
    for (int i = 0; i < scaledLayouts.length; i++) {
      final photoLayout = scaledLayouts[i];

      // Calculate actual positions and sizes based on NEW template size with stretch
      final actualPosition = Offset(
        photoLayout.position.dx * _templateSize.width * stretchFactor,
        photoLayout.position.dy * _templateSize.height * stretchFactor,
      );

      // Apply stretch factor to sizes to fill template better
      final actualSize = Size(
        photoLayout.size.width * _templateSize.width * stretchFactor,
        photoLayout.size.height * _templateSize.height * stretchFactor,
      );

      // Restore photo if it existed
      PhotoBox photoBox;
      if (_customLayoutSnapshot!.photoPathsMap.containsKey(i)) {
        final imagePath = _customLayoutSnapshot!.photoPathsMap[i]!;
        final imageFit = _customLayoutSnapshot!.photoFitsMap[i] ?? BoxFit.cover;

        photoBox = PhotoBox(
          position: actualPosition,
          size: actualSize,
          imageFile: File(imagePath),
          imagePath: imagePath,
          imageFit: imageFit,
        );
      } else {
        // Create placeholder
        photoBox = PhotoBox(
          position: actualPosition,
          size: actualSize,
          imagePath: '',
        );
      }

      _photoBoxes.add(photoBox);
    }

    // Clear selection
    _selectedBox = null;
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
      imageQuality: 95,
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
      imageQuality: 95,
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

  /// Move a photo box to a new position
  void moveBox(PhotoBox box, Offset delta) {
    final newX = box.position.dx + delta.dx;
    final newY = box.position.dy + delta.dy;

    // Apply snapping to the new position
    final snappedPosition = _applySnapping(Offset(newX, newY), box);

    // Apply inner margin spacing between photos
    final adjustedPosition = _applyInnerMarginSpacing(snappedPosition, box);

    // Ensure the photo doesn't go outside the background boundaries
    final clampedPosition = Offset(
      adjustedPosition.dx.clamp(0.0, _templateSize.width - box.size.width),
      adjustedPosition.dy.clamp(0.0, _templateSize.height - box.size.height),
    );

    box.position = clampedPosition;
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

  /// Apply inner margin spacing between photos
  Offset _applyInnerMarginSpacing(Offset position, PhotoBox movingBox) {
    if (_innerMargin <= 0) return position;

    double adjustedX = position.dx;
    double adjustedY = position.dy;

    for (final otherBox in _photoBoxes) {
      if (otherBox == movingBox) continue;

      // Check if boxes are touching or overlapping
      final movingRight = position.dx + movingBox.size.width;
      final movingBottom = position.dy + movingBox.size.height;
      final otherRight = otherBox.position.dx + otherBox.size.width;
      final otherBottom = otherBox.position.dy + otherBox.size.height;

      // Horizontal spacing
      if (movingRight <= otherBox.position.dx) {
        // Moving box is to the left of other box
        final gap = otherBox.position.dx - movingRight;
        if (gap < _innerMargin) {
          adjustedX =
              otherBox.position.dx - movingBox.size.width - _innerMargin;
        }
      } else if (position.dx >= otherRight) {
        // Moving box is to the right of other box
        final gap = position.dx - otherRight;
        if (gap < _innerMargin) {
          adjustedX = otherRight + _innerMargin;
        }
      }

      // Vertical spacing
      if (movingBottom <= otherBox.position.dy) {
        // Moving box is above other box
        final gap = otherBox.position.dy - movingBottom;
        if (gap < _innerMargin) {
          adjustedY =
              otherBox.position.dy - movingBox.size.height - _innerMargin;
        }
      } else if (position.dy >= otherBottom) {
        // Moving box is below other box
        final gap = position.dy - otherBottom;
        if (gap < _innerMargin) {
          adjustedY = otherBottom + _innerMargin;
        }
      }
    }

    return Offset(adjustedX, adjustedY);
  }

  /// Get adjusted position for photo box with inner margin
  Offset getAdjustedPosition(PhotoBox box) {
    if (_innerMargin <= 0) return box.position;

    // Apply inner margin to current position
    return _applyInnerMarginSpacing(box.position, box);
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

      // Update alignment to maintain the same visible part of the photo
      // This ensures the photo shows the same content after resize
      if (box.imageFile != null) {
        // Keep the same alignment to show the same part of the photo
        // The photo will automatically adjust to fit the new size
        box.alignment = box.alignment; // Keep current alignment
      }

      notifyListeners();
    }
  }

  /// Update available canvas area from LayoutBuilder and recompute size
  void updateAvailableArea(Size area) {
    _availableArea = area;
    final newSize = _sizeForAspect(_selectedAspect, screenSize: _availableArea);
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
      final int targetWidth = 2000; // Higher quality base width
      final int targetHeight = (targetWidth / aspectRatio).round();

      // Create a custom painter for the collage
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw background (solid or gradient)
      final rect = Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());
      if (_backgroundMode == BackgroundMode.gradient) {
        final angle = _backgroundGradient.angleDeg * math.pi / 180.0;
        final cx = targetWidth / 2.0;
        final cy = targetHeight / 2.0;
        final dx = math.cos(angle);
        final dy = math.sin(angle);
        final halfDiag = 0.5 * math.sqrt(targetWidth * targetWidth + targetHeight * targetHeight);
        final start = Offset(cx - dx * halfDiag, cy - dy * halfDiag);
        final end = Offset(cx + dx * halfDiag, cy + dy * halfDiag);

        final colors = _backgroundGradient.stops
            .map((s) => s.color.withValues(alpha: s.color.a * _backgroundOpacity))
            .toList();
        final stops = _backgroundGradient.stops.map((s) => s.offset).toList();
        final shader = ui.Gradient.linear(start, end, colors, stops);
        final paint = Paint()..shader = shader;
        canvas.drawRect(rect, paint);
      } else {
        final paint = Paint()..color = backgroundColorWithOpacity;
        canvas.drawRect(rect, paint);
      }

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

              // Apply photo margin
              final double mX = photoMargin * scaleX;
              final double mY = photoMargin * scaleY;
              final Rect dstRect = Rect.fromLTWH(
                scaledPosition.dx + mX,
                scaledPosition.dy + mY,
                math.max(1, scaledSize.width - 2 * mX),
                math.max(1, scaledSize.height - 2 * mY),
              );

              // Compute source rect according to fit and alignment (cover by default)
              final Rect srcRect = _computeSrcRectForFit(
                image,
                dstRect.size,
                box.imageFit,
                box.alignment,
                box.photoScale,
              );

              // Clip for corner radius
              final double r = cornerRadius * ((scaleX + scaleY) / 2);
              canvas.save();
              if (r > 0) {
                canvas.clipRRect(RRect.fromRectAndRadius(dstRect, Radius.circular(r)));
              } else {
                canvas.clipRect(dstRect);
              }

              final paintImg = Paint()
                ..isAntiAlias = true
                ..filterQuality = FilterQuality.high;
              canvas.drawImageRect(image, srcRect, dstRect, paintImg);
              canvas.restore();

              // Draw borders if enabled
              if (_hasGlobalBorder && _globalBorderWidth > 0) {
                _drawSimpleBorders(
                  canvas,
                  Offset(dstRect.left, dstRect.top),
                  Size(dstRect.width, dstRect.height),
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

  /// Compute source crop rect for given fit/alignment
  Rect _computeSrcRectForFit(
    ui.Image image,
    Size dstSize,
    BoxFit fit,
    Alignment alignment,
    double additionalScale,
  ) {
    final double imgW = image.width.toDouble();
    final double imgH = image.height.toDouble();
    if (fit == BoxFit.fill) {
      return Rect.fromLTWH(0, 0, imgW, imgH);
    }
    if (fit == BoxFit.contain) {
      final double scale = math.min(dstSize.width / imgW, dstSize.height / imgH);
      final double visibleW = imgW;
      final double visibleH = imgH;
      return Rect.fromLTWH(0, 0, visibleW, visibleH);
    }
    // Default: cover
    double scale = math.max(dstSize.width / imgW, dstSize.height / imgH);
    if (additionalScale.isFinite && additionalScale > 0) {
      scale *= additionalScale;
    }
    final double cropW = dstSize.width / scale;
    final double cropH = dstSize.height / scale;
    final double extraW = imgW - cropW;
    final double extraH = imgH - cropH;
    final double alignX = (alignment.x + 1) / 2; // 0..1
    final double alignY = (alignment.y + 1) / 2; // 0..1
    final double left = extraW * alignX.clamp(0.0, 1.0);
    final double top = extraH * alignY.clamp(0.0, 1.0);
    return Rect.fromLTWH(left, top, cropW, cropH);
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
