part of '../collage_manager.dart';

/// Snapshot of custom layout for aspect ratio transitions
class CustomLayoutSnapshot {
  final List<PhotoLayout> photoLayouts;
  final AspectSpec originalAspect;
  final Map<int, String> photoPathsMap; // Store photo paths by index
  final Map<int, BoxFit> photoFitsMap; // Store photo fits by index
  final Map<int, Alignment> photoAlignsMap; // Store alignment by index
  final Map<int, double> photoScalesMap; // Store scale by index
  final Map<int, double> photoRotationsMap; // Store rotation (radians)
  final Map<int, double> photoRotationBasesMap; // Store rotation base (gesture)

  CustomLayoutSnapshot({
    required this.photoLayouts,
    required this.originalAspect,
    required this.photoPathsMap,
    required this.photoFitsMap,
    required this.photoAlignsMap,
    required this.photoScalesMap,
    required this.photoRotationsMap,
    required this.photoRotationBasesMap,
  });
}

mixin _CollageLayoutControls on _CollageManagerBase {
  /// Calculate template size based on aspect ratio and available area.
  /// [screenSize] represents the available canvas area, not the full screen.
  Size _sizeForAspect(AspectSpec a, {Size? screenSize}) {
    double availW = _kCollageBaseWidth;
    double availH = _kCollageBaseWidth;
    if (screenSize != null) {
      const double sideMargin = 40.0; // left+right total
      const double vertMargin = 80.0; // top+bottom total

      availW = screenSize.width - sideMargin;
      availH = screenSize.height - vertMargin;

      if (availW < 260) availW = 260;
      if (availH < 220) availH = 220;
    }

    final double r = a.ratio; // width / height

    double width, height;
    if (availH * r <= availW) {
      height = availH;
      width = height * r;
    } else {
      width = availW;
      height = width / r;
    }

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

  /// Apply new aspect ratio and resize existing boxes accordingly.
  void applyAspect(AspectSpec newAspect, {Size? screenSize}) {
    if (newAspect.w <= 0 || newAspect.h <= 0) return;

    final Size previousTemplateSize = _templateSize;
    _selectedAspect = newAspect;
    final area = _availableArea ?? screenSize;
    _templateSize = _sizeForAspect(newAspect, screenSize: area);

    if (_currentLayout != null && !_isCustomMode) {
      _updateLayoutForAspectRatio();
    } else {
      if (_photoBoxes.isNotEmpty) {
        _createCustomLayoutSnapshot(templateSizeOverride: previousTemplateSize);
        _applyCustomLayoutSnapshot(newAspect);
      }
    }

    notifyListeners();
  }

  /// Set or update the current custom aspect entry (shown in selector list).
  void setCustomAspect(AspectSpec custom) {
    _customAspect = custom;
    notifyListeners();
  }

  /// Create a snapshot of current custom layout to ease aspect transitions.
  void _createCustomLayoutSnapshot({Size? templateSizeOverride}) {
    if (!_isCustomMode || _photoBoxes.isEmpty) return;

    final Size templateSize = templateSizeOverride ?? _templateSize;

    final photoLayouts = <PhotoLayout>[];
    final photoPathsMap = <int, String>{};
    final photoFitsMap = <int, BoxFit>{};
    final photoAlignsMap = <int, Alignment>{};
    final photoScalesMap = <int, double>{};
    final photoRotationsMap = <int, double>{};
    final photoRotationBasesMap = <int, double>{};

    for (int i = 0; i < _photoBoxes.length; i++) {
      final box = _photoBoxes[i];

      final normalizedX = box.position.dx / templateSize.width;
      final normalizedY = box.position.dy / templateSize.height;
      final normalizedWidth = box.size.width / templateSize.width;
      final normalizedHeight = box.size.height / templateSize.height;

      photoLayouts.add(
        PhotoLayout(
          position: Offset(normalizedX, normalizedY),
          size: Size(normalizedWidth, normalizedHeight),
        ),
      );

      if (box.imageFile != null &&
          box.imagePath != null &&
          box.imagePath!.isNotEmpty) {
        photoPathsMap[i] = box.imagePath!;
        photoFitsMap[i] = box.imageFit;
        photoAlignsMap[i] = box.alignment;
        photoScalesMap[i] = box.photoScale;
      }

      photoRotationsMap[i] = box.rotationRadians;
      photoRotationBasesMap[i] = box.rotationBaseRadians;
    }

    _customLayoutSnapshot = CustomLayoutSnapshot(
      photoLayouts: photoLayouts,
      originalAspect: _selectedAspect,
      photoPathsMap: photoPathsMap,
      photoFitsMap: photoFitsMap,
      photoAlignsMap: photoAlignsMap,
      photoScalesMap: photoScalesMap,
      photoRotationsMap: photoRotationsMap,
      photoRotationBasesMap: photoRotationBasesMap,
    );
  }

  /// Apply custom layout snapshot to new aspect ratio.
  void _applyCustomLayoutSnapshot(AspectSpec newAspect) {
    if (_customLayoutSnapshot == null) return;

    _photoBoxes.clear();

    final layouts = _customLayoutSnapshot!.photoLayouts;

    for (int i = 0; i < layouts.length; i++) {
      final l = layouts[i];
      final actualPosition = Offset(
        l.position.dx * _templateSize.width,
        l.position.dy * _templateSize.height,
      );
      final actualSize = Size(
        l.size.width * _templateSize.width,
        l.size.height * _templateSize.height,
      );

      final double rotation =
          _customLayoutSnapshot!.photoRotationsMap[i] ?? 0.0;
      final double rotationBase =
          _customLayoutSnapshot!.photoRotationBasesMap[i] ?? rotation;

      PhotoBox photoBox;
      if (_customLayoutSnapshot!.photoPathsMap.containsKey(i)) {
        final imagePath = _customLayoutSnapshot!.photoPathsMap[i]!;
        final imageFit = _customLayoutSnapshot!.photoFitsMap[i] ?? BoxFit.cover;
        final align = _customLayoutSnapshot!.photoAlignsMap[i] ?? Alignment.center;
        final pScale = _customLayoutSnapshot!.photoScalesMap[i] ?? 1.0;

        photoBox = PhotoBox(
          position: actualPosition,
          size: actualSize,
          imageFile: File(imagePath),
          imagePath: imagePath,
          imageFit: imageFit,
          alignment: align,
          photoScale: pScale,
          rotationRadians: rotation,
          rotationBaseRadians: rotationBase,
        );
      } else {
        photoBox = PhotoBox(
          position: actualPosition,
          size: actualSize,
          imagePath: '',
          rotationRadians: rotation,
          rotationBaseRadians: rotationBase,
        );
      }

      photoBox.position = _clampBoxWithinTemplate(photoBox, actualPosition);

      _photoBoxes.add(photoBox);
    }

    _selectedBox = null;
  }

  /// Apply or clear a layout template.
  void applyLayoutTemplate(LayoutTemplate? layout) {
    if (layout == null) {
      _currentLayout = null;
      _isCustomMode = true;
      _photoBoxes.clear();
      _selectedBox = null;
      _photoMargin = 0.0;
      _shadowIntensity = 0.0;
      _innerMargin = 0.0;
      _outerMargin = 0.0;
      _cornerRadius = 0.0;
      _globalBorderWidth = 0.0;
      _hasGlobalBorder = false;
      notifyListeners();
      return;
    }

    _currentLayout = layout;
    _isCustomMode = false;

    _photoBoxes.clear();
    _shadowIntensity = 0.0;
    _innerMargin = 0.0;
    _outerMargin = 0.0;
    _cornerRadius = 0.0;
    _globalBorderWidth = 0.0;
    _hasGlobalBorder = false;

    final scaledLayouts = layout.getScaledLayouts(
      _selectedAspect.w / _selectedAspect.h,
    );

    for (int i = 0; i < layout.photoLayouts.length; i++) {
      final photoLayout = scaledLayouts[i];
      final actualPosition = Offset(
        photoLayout.position.dx * _templateSize.width,
        photoLayout.position.dy * _templateSize.height,
      );

      final actualSize = Size(
        photoLayout.size.width * _templateSize.width,
        photoLayout.size.height * _templateSize.height,
      );

      final photoBox = PhotoBox(
        position: actualPosition,
        size: actualSize,
        imagePath: '',
      );

      _photoBoxes.add(photoBox);
    }

    _selectedBox = null;
    _photoMargin = 1.0;

    notifyListeners();
  }

  /// Update layout when aspect ratio changes for preset templates.
  void _updateLayoutForAspectRatio() {
    if (_currentLayout == null || _isCustomMode) {
      return;
    }

    final existingPhotos = Map<int, PhotoBox>.fromEntries(
      _photoBoxes.asMap().entries,
    );

    _photoBoxes.clear();

    final scaledLayouts = _currentLayout!.getScaledLayouts(
      _selectedAspect.w / _selectedAspect.h,
    );

    for (int i = 0; i < scaledLayouts.length; i++) {
      final photoLayout = scaledLayouts[i];

      final actualPosition = Offset(
        photoLayout.position.dx * _templateSize.width,
        photoLayout.position.dy * _templateSize.height,
      );

      final actualSize = Size(
        photoLayout.size.width * _templateSize.width,
        photoLayout.size.height * _templateSize.height,
      );

      PhotoBox photoBox;
      if (existingPhotos.containsKey(i) &&
          existingPhotos[i]!.imageFile != null) {
        final existing = existingPhotos[i]!;
        photoBox = PhotoBox(
          position: actualPosition,
          size: actualSize,
          imageFile: existing.imageFile,
          imagePath: existing.imagePath,
          imageFit: existing.imageFit,
          alignment: existing.alignment,
          photoScale: existing.photoScale,
        );
      } else {
        photoBox = PhotoBox(
          position: actualPosition,
          size: actualSize,
          imagePath: '',
        );
      }

      _photoBoxes.add(photoBox);
    }

    _selectedBox = null;

    notifyListeners();
  }

  /// Update available canvas area from LayoutBuilder and recompute template size.
  void updateAvailableArea(Size area) {
    _availableArea = area;
    final newSize = _sizeForAspect(_selectedAspect, screenSize: _availableArea);
    if (_templateSize == newSize) {
      return;
    }

    final oldSize = _templateSize;
    _templateSize = newSize;

    if (oldSize.width > 0 && oldSize.height > 0 && _photoBoxes.isNotEmpty) {
      final sx = newSize.width / oldSize.width;
      final sy = newSize.height / oldSize.height;
      for (final b in _photoBoxes) {
        b.position = Offset(b.position.dx * sx, b.position.dy * sy);
        b.size = Size(b.size.width * sx, b.size.height * sy);
      }
    }

    suppressNextHistoryEntry();
    notifyListeners();
  }
}
