library collage_manager_service;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';

import '../models/alignment_guideline.dart';
import '../models/aspect_spec.dart';
import '../models/background.dart';
import '../models/layout_template.dart';
import '../models/photo_box.dart';
import '../utils/collage_utils.dart';

part 'collage_manager/background_controls.dart';
part 'collage_manager/export_controls.dart';
part 'collage_manager/guideline_controls.dart';
part 'collage_manager/layout_controls.dart';
part 'collage_manager/photo_box_controls.dart';
part 'collage_manager/transform_controls.dart';

const double _kCollageBaseWidth = 350;
const double _kCollageMinHeight = 220;

/// Preset option used when exporting the collage image
class ResolutionOption {
  final String label;
  final int width;

  const ResolutionOption({
    required this.label,
    required this.width,
  });
}

/// Shared state and defaults for the collage manager service.
abstract class _CollageManagerBase extends ChangeNotifier {
  // Export resolution presets
  static const List<ResolutionOption> _resolutionOptions = [
    ResolutionOption(label: 'Standard', width: 2000),
    ResolutionOption(label: 'High', width: 3000),
    ResolutionOption(label: 'Ultra', width: 4000),
  ];

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

  // State variables
  AspectSpec _selectedAspect = _presets.firstWhere((a) => a.label == '9:16');
  AspectSpec? _customAspect; // Last custom ratio selected via slider
  Size _templateSize = const Size(_kCollageBaseWidth, _kCollageBaseWidth);
  Size? _availableArea; // last known canvas available area from LayoutBuilder
  final List<PhotoBox> _photoBoxes = [];
  PhotoBox? _selectedBox;
  bool _snappingSuspended = false;

  // Background color and opacity (canvas default stays white; user can change)
  Color _backgroundColor = Colors.white;
  double _backgroundOpacity = 1.0;
  BackgroundMode _backgroundMode = BackgroundMode.solid;
  // Keep a default gradient spec available for when user switches to gradient
  GradientSpec _backgroundGradient = GradientSpec(
    stops: [
      GradientStop(offset: 0.0, color: Colors.white),
      GradientStop(offset: 1.0, color: Colors.white),
    ],
    angleDeg: 0,
  );

  // Global border settings
  double _globalBorderWidth = 0.0; // Start with 0 margin
  Color _globalBorderColor = Colors.white; // Visible default
  bool _hasGlobalBorder = false;

  // Photo margin settings (separate from border)
  double _photoMargin = 0.0; // Spacing between photos

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

  // Export resolution state
  int _selectedExportWidth = _resolutionOptions[1].width;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();

  // Getters
  AspectSpec get selectedAspect => _selectedAspect;
  Size get templateSize => _templateSize;
  List<PhotoBox> get photoBoxes => List.unmodifiable(_photoBoxes);
  PhotoBox? get selectedBox => _selectedBox;
  List<AspectSpec> get presets => List.unmodifiable(_presets);
  List<AspectSpec> get presetsWithCustom =>
      _customAspect != null ? List.unmodifiable([..._presets, _customAspect!]) : presets;
  AspectSpec? get customAspect => _customAspect;

  // Background color and opacity getters
  Color get backgroundColor => _backgroundColor;
  double get backgroundOpacity => _backgroundOpacity;
  BackgroundMode get backgroundMode => _backgroundMode;
  GradientSpec get backgroundGradient => _backgroundGradient;

  // Border getters
  bool get hasGlobalBorder => _hasGlobalBorder;
  double get globalBorderWidth => _globalBorderWidth;
  Color get globalBorderColor => _globalBorderColor;

  // Border effect getters
  double get shadowIntensity => _shadowIntensity;
  double get innerMargin => _innerMargin;
  double get outerMargin => _outerMargin;
  double get cornerRadius => _cornerRadius;

  // Layout template getters
  LayoutTemplate? get currentLayout => _currentLayout;
  bool get isCustomMode => _isCustomMode;

  // Export resolution getters
  List<ResolutionOption> get resolutionOptions => List.unmodifiable(_resolutionOptions);
  int get selectedExportWidth => _selectedExportWidth;

  // Photo margin getter
  double get photoMargin => _photoMargin;

  // Derived background color including opacity
  Color get backgroundColorWithOpacity =>
      _backgroundColor.withValues(alpha: _backgroundOpacity);

  void refresh() => notifyListeners();

  /// Temporarily suspend snapping/guideline behaviour (e.g., during rotation)
  void setSnappingSuspended(bool value) {
    if (_snappingSuspended == value) return;
    _snappingSuspended = value;
    notifyListeners();
  }

  Offset _clampBoxWithinTemplate(PhotoBox box, Offset position) {
    const double minSize = 50.0;
    double width = box.size.width;
    double height = box.size.height;

    final Offset desiredCenter =
        Offset(position.dx + width * 0.5, position.dy + height * 0.5);

    final double angle = box.rotationRadians;
    final double absCos = math.cos(angle).abs();
    final double absSin = math.sin(angle).abs();

    double boundWidth = (absCos * width) + (absSin * height);
    double boundHeight = (absSin * width) + (absCos * height);

    double scale = 1.0;
    if (boundWidth > _templateSize.width || boundHeight > _templateSize.height) {
      final double sx = _templateSize.width / boundWidth;
      final double sy = _templateSize.height / boundHeight;
      scale = math.min(math.min(sx, sy), 1.0);
      if (scale < 1.0 && scale.isFinite && scale > 0) {
        width = math.max(minSize, width * scale);
        height = math.max(minSize, height * scale);
        box.size = Size(width, height);

        boundWidth = (absCos * width) + (absSin * height);
        boundHeight = (absSin * width) + (absCos * height);
      }
    }

    double minCenterX = boundWidth * 0.5;
    double maxCenterX = _templateSize.width - boundWidth * 0.5;
    double minCenterY = boundHeight * 0.5;
    double maxCenterY = _templateSize.height - boundHeight * 0.5;

    if (minCenterX > maxCenterX) {
      final double cx = _templateSize.width * 0.5;
      minCenterX = cx;
      maxCenterX = cx;
    }
    if (minCenterY > maxCenterY) {
      final double cy = _templateSize.height * 0.5;
      minCenterY = cy;
      maxCenterY = cy;
    }

    final double clampedCenterX = desiredCenter.dx.clamp(minCenterX, maxCenterX);
    final double clampedCenterY = desiredCenter.dy.clamp(minCenterY, maxCenterY);

    return Offset(
      clampedCenterX - width * 0.5,
      clampedCenterY - height * 0.5,
    );
  }
}

/// Service class for managing collage operations and state
class CollageManager extends _CollageManagerBase
    with
        _CollageBackgroundControls,
        _CollageLayoutControls,
        _CollagePhotoBoxControls,
        _CollageTransformControls,
        _CollageExportControls,
        _CollageGuidelineControls {
  static const double baseWidth = _kCollageBaseWidth;
  static const double minHeight = _kCollageMinHeight;
}
