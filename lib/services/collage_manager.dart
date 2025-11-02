import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saver_gallery/saver_gallery.dart';

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

class _PhotoBoxSnapshot {
  final Offset position;
  final Size size;
  final String? imagePath;
  final BoxFit imageFit;
  final Offset photoOffset;
  final double photoScale;
  final Rect cropRect;
  final Alignment alignment;
  final double rotationRadians;
  final double rotationBaseRadians;

  const _PhotoBoxSnapshot({
    required this.position,
    required this.size,
    required this.imagePath,
    required this.imageFit,
    required this.photoOffset,
    required this.photoScale,
    required this.cropRect,
    required this.alignment,
    required this.rotationRadians,
    required this.rotationBaseRadians,
  });

  factory _PhotoBoxSnapshot.fromPhotoBox(PhotoBox box) {
    return _PhotoBoxSnapshot(
      position: box.position,
      size: box.size,
      imagePath: box.imagePath,
      imageFit: box.imageFit,
      photoOffset: box.photoOffset,
      photoScale: box.photoScale,
      cropRect: box.cropRect,
      alignment: box.alignment,
      rotationRadians: box.rotationRadians,
      rotationBaseRadians: box.rotationBaseRadians,
    );
  }

  PhotoBox toPhotoBox() {
    final String? path = imagePath;
    final File? file =
        (path != null && path.isNotEmpty) ? File(path) : null;
    return PhotoBox(
      position: position,
      size: size,
      imageFile: file,
      imagePath: path,
      imageFit: imageFit,
      photoOffset: photoOffset,
      photoScale: photoScale,
      cropRect: cropRect,
      alignment: alignment,
      rotationRadians: rotationRadians,
      rotationBaseRadians: rotationBaseRadians,
    );
  }

  bool isEquivalentTo(_PhotoBoxSnapshot other) {
    return position == other.position &&
        size == other.size &&
        imagePath == other.imagePath &&
        imageFit == other.imageFit &&
        photoOffset == other.photoOffset &&
        photoScale == other.photoScale &&
        cropRect == other.cropRect &&
        alignment == other.alignment &&
        rotationRadians == other.rotationRadians &&
        rotationBaseRadians == other.rotationBaseRadians;
  }
}

GradientSpec _cloneGradientSpec(GradientSpec spec) {
  return GradientSpec(
    stops: spec.stops
        .map((s) => GradientStop(offset: s.offset, color: s.color))
        .toList(),
    angleDeg: spec.angleDeg,
  );
}

CustomLayoutSnapshot? _cloneCustomLayoutSnapshot(
  CustomLayoutSnapshot? snapshot,
) {
  if (snapshot == null) return null;
  return CustomLayoutSnapshot(
    photoLayouts: snapshot.photoLayouts
        .map(
          (p) => PhotoLayout(position: p.position, size: p.size),
        )
        .toList(),
    originalAspect: snapshot.originalAspect,
    photoPathsMap: Map<int, String>.from(snapshot.photoPathsMap),
    photoFitsMap: Map<int, BoxFit>.from(snapshot.photoFitsMap),
    photoAlignsMap: Map<int, Alignment>.from(snapshot.photoAlignsMap),
    photoScalesMap: Map<int, double>.from(snapshot.photoScalesMap),
    photoRotationsMap: Map<int, double>.from(snapshot.photoRotationsMap),
    photoRotationBasesMap:
        Map<int, double>.from(snapshot.photoRotationBasesMap),
  );
}

class _CollageSnapshot {
  final List<_PhotoBoxSnapshot> boxes;
  final int? selectedIndex;
  final AspectSpec selectedAspect;
  final AspectSpec? customAspect;
  final Size templateSize;
  final Size? availableArea;
  final bool isCustomMode;
  final String? currentLayoutId;
  final Color backgroundColor;
  final double backgroundOpacity;
  final BackgroundMode backgroundMode;
  final GradientSpec gradientSpec;
  final double globalBorderWidth;
  final Color globalBorderColor;
  final bool hasGlobalBorder;
  final double photoMargin;
  final double shadowIntensity;
  final double innerMargin;
  final double outerMargin;
  final double cornerRadius;
  final CustomLayoutSnapshot? customLayoutSnapshot;

  const _CollageSnapshot({
    required this.boxes,
    required this.selectedIndex,
    required this.selectedAspect,
    required this.customAspect,
    required this.templateSize,
    required this.availableArea,
    required this.isCustomMode,
    required this.currentLayoutId,
    required this.backgroundColor,
    required this.backgroundOpacity,
    required this.backgroundMode,
    required this.gradientSpec,
    required this.globalBorderWidth,
    required this.globalBorderColor,
    required this.hasGlobalBorder,
    required this.photoMargin,
    required this.shadowIntensity,
    required this.innerMargin,
    required this.outerMargin,
    required this.cornerRadius,
    required this.customLayoutSnapshot,
  });

  bool isEquivalentTo(_CollageSnapshot other) {
    if (boxes.length != other.boxes.length) {
      return false;
    }
    for (int i = 0; i < boxes.length; i++) {
      if (!boxes[i].isEquivalentTo(other.boxes[i])) {
        return false;
      }
    }
    if (selectedIndex != other.selectedIndex) {
      return false;
    }
    if (selectedAspect.w != other.selectedAspect.w ||
        selectedAspect.h != other.selectedAspect.h) {
      return false;
    }
    if ((customAspect?.w ?? -1) != (other.customAspect?.w ?? -1) ||
        (customAspect?.h ?? -1) != (other.customAspect?.h ?? -1)) {
      return false;
    }
    if (templateSize != other.templateSize ||
        availableArea != other.availableArea ||
        isCustomMode != other.isCustomMode ||
        currentLayoutId != other.currentLayoutId ||
        backgroundColor.toARGB32() != other.backgroundColor.toARGB32() ||
        backgroundOpacity != other.backgroundOpacity ||
        backgroundMode != other.backgroundMode ||
        gradientSpec.angleDeg != other.gradientSpec.angleDeg ||
        globalBorderWidth != other.globalBorderWidth ||
        globalBorderColor.toARGB32() != other.globalBorderColor.toARGB32() ||
        hasGlobalBorder != other.hasGlobalBorder ||
        photoMargin != other.photoMargin ||
        shadowIntensity != other.shadowIntensity ||
        innerMargin != other.innerMargin ||
        outerMargin != other.outerMargin ||
        cornerRadius != other.cornerRadius) {
      return false;
    }
    if (gradientSpec.stops.length != other.gradientSpec.stops.length) {
      return false;
    }
    for (int i = 0; i < gradientSpec.stops.length; i++) {
      final a = gradientSpec.stops[i];
      final b = other.gradientSpec.stops[i];
      if (a.offset != b.offset ||
          a.color.toARGB32() != b.color.toARGB32()) {
        return false;
      }
    }
    return true;
  }
}

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
  static const int _historyLimit = 40;
  final List<_CollageSnapshot> _undoStack = [];
  final List<_CollageSnapshot> _redoStack = [];
  _CollageSnapshot? _currentSnapshot;
  bool _applyingHistory = false;
  bool _suppressNextHistory = false;
  _CollageSnapshot? _checkpointSnapshot;

  _CollageManagerBase() {
    _currentSnapshot = _captureSnapshot();
  }

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

  // Premium access
  bool _isPremium = false;
  int _weeklySavesUsed = 0;
  DateTime? _trialStart;

  static const Duration _trialDuration = Duration(days: 3);

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

  bool get isPremium => _isPremium;
  bool get isFreeUser => !_isPremium;
  int get weeklySavesUsed => _weeklySavesUsed;
  bool get canStartTrial => !_isPremium && _trialStart == null;
  bool get isTrialActive {
    if (_trialStart == null) return false;
    return DateTime.now().difference(_trialStart!) < _trialDuration;
  }

  bool get hasTrialEnded => _trialStart != null && !isTrialActive;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get trialDaysRemaining {
    if (!isTrialActive || _trialStart == null) return 0;
    final elapsed = DateTime.now().difference(_trialStart!);
    final remaining = _trialDuration - elapsed;
    if (remaining.isNegative) return 0;
    final hours = remaining.inHours + (remaining.inMinutes % 60 > 0 ? 1 : 0);
    final days = (hours / 24).ceil();
    return days > 0 ? days : 0;
  }

  int get weeklySaveLimit => _isPremium || isTrialActive ? -1 : 3;

  int get freeSavesRemaining {
    if (_isPremium || isTrialActive) return -1;
    final limit = weeklySaveLimit;
    if (limit <= 0) return -1;
    final remaining = limit - _weeklySavesUsed;
    return remaining < 0 ? 0 : remaining;
  }

  // Derived background color including opacity
  Color get backgroundColorWithOpacity =>
      _backgroundColor.withValues(alpha: _backgroundOpacity);

  void setPremium(bool value) {
    if (_isPremium == value) return;
    _isPremium = value;
    if (value) {
      _weeklySavesUsed = 0;
    }
    notifyListeners();
  }

  bool startTrial() {
    if (!canStartTrial) return false;
    _trialStart = DateTime.now();
    _weeklySavesUsed = 0;
    notifyListeners();
    return true;
  }

  void resetWeeklyUsage() {
    _weeklySavesUsed = 0;
    notifyListeners();
  }

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

  void suppressNextHistoryEntry() {
    _suppressNextHistory = true;
  }

  void undo() {
    if (!canUndo) return;
    final _CollageSnapshot previous = _undoStack.removeLast();
    final _CollageSnapshot? currentBeforeUndo = _currentSnapshot;
    if (currentBeforeUndo != null) {
      if (_redoStack.length >= _historyLimit) {
        _redoStack.removeAt(0);
      }
      _redoStack.add(currentBeforeUndo);
    }
    _applyingHistory = true;
    _restoreSnapshot(previous);
    _currentSnapshot = previous;
    notifyListeners();
    _applyingHistory = false;
  }

  void redo() {
    if (!canRedo) return;
    final _CollageSnapshot next = _redoStack.removeLast();
    final _CollageSnapshot? currentBeforeRedo = _currentSnapshot;
    if (currentBeforeRedo != null) {
      if (_undoStack.length >= _historyLimit) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(currentBeforeRedo);
    }
    _applyingHistory = true;
    _restoreSnapshot(next);
    _currentSnapshot = next;
    notifyListeners();
    _applyingHistory = false;
  }

  @override
  void notifyListeners() {
    _recordSnapshotIfNeeded();
    super.notifyListeners();
  }

  void _recordSnapshotIfNeeded() {
    final newSnapshot = _captureSnapshot();
    if (_currentSnapshot == null) {
      _currentSnapshot = newSnapshot;
      return;
    }
    if (_checkpointSnapshot != null) {
      _currentSnapshot = newSnapshot;
      return;
    }
    if (_applyingHistory) {
      _currentSnapshot = newSnapshot;
      return;
    }
    if (_suppressNextHistory) {
      _suppressNextHistory = false;
      _currentSnapshot = newSnapshot;
      return;
    }
    if (!_currentSnapshot!.isEquivalentTo(newSnapshot)) {
      if (_undoStack.length >= _historyLimit) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(_currentSnapshot!);
      _redoStack.clear();
      _currentSnapshot = newSnapshot;
    }
  }

  _CollageSnapshot _captureSnapshot() {
    final boxes = _photoBoxes
        .map((box) => _PhotoBoxSnapshot.fromPhotoBox(box))
        .toList();
    final selectedIndex = _selectedBox != null
        ? _photoBoxes.indexOf(_selectedBox!)
        : null;
    return _CollageSnapshot(
      boxes: boxes,
      selectedIndex: selectedIndex,
      selectedAspect: _selectedAspect,
      customAspect: _customAspect,
      templateSize: _templateSize,
      availableArea: _availableArea,
      isCustomMode: _isCustomMode,
      currentLayoutId: _currentLayout?.id,
      backgroundColor: _backgroundColor,
      backgroundOpacity: _backgroundOpacity,
      backgroundMode: _backgroundMode,
      gradientSpec: _cloneGradientSpec(_backgroundGradient),
      globalBorderWidth: _globalBorderWidth,
      globalBorderColor: _globalBorderColor,
      hasGlobalBorder: _hasGlobalBorder,
      photoMargin: _photoMargin,
      shadowIntensity: _shadowIntensity,
      innerMargin: _innerMargin,
      outerMargin: _outerMargin,
      cornerRadius: _cornerRadius,
      customLayoutSnapshot: _cloneCustomLayoutSnapshot(_customLayoutSnapshot),
    );
  }

  void _restoreSnapshot(_CollageSnapshot snapshot) {
    _photoBoxes
      ..clear()
      ..addAll(snapshot.boxes.map((b) => b.toPhotoBox()));

    if (snapshot.selectedIndex != null &&
        snapshot.selectedIndex! >= 0 &&
        snapshot.selectedIndex! < _photoBoxes.length) {
      _selectedBox = _photoBoxes[snapshot.selectedIndex!];
    } else {
      _selectedBox = null;
    }

    _selectedAspect = snapshot.selectedAspect;
    _customAspect = snapshot.customAspect;
    _templateSize = snapshot.templateSize;
    _availableArea = snapshot.availableArea;
    _isCustomMode = snapshot.isCustomMode;
    _currentLayout = _findLayoutById(snapshot.currentLayoutId);
    _backgroundColor = snapshot.backgroundColor;
    _backgroundOpacity = snapshot.backgroundOpacity;
    _backgroundMode = snapshot.backgroundMode;
    _backgroundGradient = _cloneGradientSpec(snapshot.gradientSpec);
    _globalBorderWidth = snapshot.globalBorderWidth;
    _globalBorderColor = snapshot.globalBorderColor;
    _hasGlobalBorder = snapshot.hasGlobalBorder;
    _photoMargin = snapshot.photoMargin;
    _shadowIntensity = snapshot.shadowIntensity;
    _innerMargin = snapshot.innerMargin;
    _outerMargin = snapshot.outerMargin;
    _cornerRadius = snapshot.cornerRadius;
    _customLayoutSnapshot =
        _cloneCustomLayoutSnapshot(snapshot.customLayoutSnapshot);
  }

  void startHistoryCheckpoint() {
    if (_applyingHistory) return;
    _checkpointSnapshot ??= _captureSnapshot();
  }

  void finalizeHistoryCheckpoint() {
    if (_applyingHistory) return;
    if (_checkpointSnapshot == null) return;
    final current = _captureSnapshot();
    if (!_checkpointSnapshot!.isEquivalentTo(current)) {
      if (_undoStack.length >= _historyLimit) {
        _undoStack.removeAt(0);
      }
      _undoStack.add(_checkpointSnapshot!);
      _redoStack.clear();
    }
    _currentSnapshot = current;
    _checkpointSnapshot = null;
  }

  void cancelHistoryCheckpoint() {
    if (_applyingHistory) return;
    _checkpointSnapshot = null;
  }

  LayoutTemplate? _findLayoutById(String? id) {
    if (id == null) return null;
    try {
      return LayoutTemplates.templates.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
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
