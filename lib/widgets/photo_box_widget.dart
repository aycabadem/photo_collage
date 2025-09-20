import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:my_appflutter/screens/photo_editor_page.dart';
import '../models/photo_box.dart';
import '../widgets/smart_border_overlay.dart';
import '../services/collage_manager.dart';

/// Widget for displaying a single photo box in the collage
class PhotoBoxWidget extends StatefulWidget {
  /// The photo box data to display
  final PhotoBox box;

  /// Whether this box is currently selected
  final bool isSelected;

  /// Callback when the box is tapped
  final VoidCallback onTap;

  /// Callback when the box is dragged
  final void Function(DragUpdateDetails) onPanUpdate;

  /// Callback when the delete button is tapped
  final VoidCallback onDelete;

  /// Callback when add photo button is tapped
  final Future<void> Function()? onAddPhoto;

  /// Callback when photo is modified (pan/zoom changes)
  final VoidCallback? onPhotoModified;

  /// Global border settings from CollageManager
  final double globalBorderWidth;
  final Color globalBorderColor;
  final bool hasGlobalBorder;

  /// Other photo boxes for smart border detection
  final List<PhotoBox> otherBoxes;

  /// CollageManager for accessing new border effects
  final CollageManager collageManager;

  /// Notify parent when a rotation gesture becomes active/inactive
  final void Function(bool active)? onRotateActive;

  const PhotoBoxWidget({
    super.key,
    required this.box,
    required this.isSelected,
    required this.onTap,
    required this.onPanUpdate,
    required this.onDelete,
    this.onAddPhoto,
    this.onPhotoModified,
    required this.globalBorderWidth,
    required this.globalBorderColor,
    required this.hasGlobalBorder,
    required this.otherBoxes,
    required this.collageManager,
    this.onRotateActive,
  });

  @override
  State<PhotoBoxWidget> createState() => _PhotoBoxWidgetState();
}

class _PhotoBoxWidgetState extends State<PhotoBoxWidget> {
  bool _rotationActive = false;
  double _rotationStartAngle = 0.0;
  double? _rotationStartPointerAngle;
  Offset? _boxCenterGlobal;
  Offset? _rotationHandleStartGlobal;
  bool _showRotationSnapGuides = false;
  double _snapGuideAngle = 0.0;

  @override
  void didUpdateWidget(covariant PhotoBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSelected && _showRotationSnapGuides) {
      _clearRotationSnapGuides();
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final bool hasImage = box.imageFile != null;
    final theme = Theme.of(context);
    final Color placeholderBorderColor =
        theme.colorScheme.primary.withValues(alpha: 0.65);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color frameColor = Color.alphaBlend(
      isDarkMode
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.85),
      theme.colorScheme.surface,
    );

    return GestureDetector(
      onDoubleTap: widget.onTap, // Double tap to select
      onScaleStart: widget.isSelected ? _handleScaleStart : null,
      onScaleUpdate: widget.isSelected ? _handleScaleUpdate : null,
      onScaleEnd: widget.isSelected ? _handleScaleEnd : null,
      behavior: HitTestBehavior.opaque, // Prevent background taps
      child: Container(
        decoration: _frameDecoration(
          cornerRadius: widget.collageManager.cornerRadius,
          intensity: widget.collageManager.shadowIntensity,
          frameColor: frameColor,
          isDarkMode: isDarkMode,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.collageManager.cornerRadius,
              ),
              child: ColoredBox(
                color: frameColor,
                child: Stack(
                  children: [
                    // Photo or placeholder
                    if (hasImage)
                      Transform.scale(
                        scale: box.photoScale,
                        alignment: box.alignment,
                        child: Image.file(
                          box.imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: box.alignment,
                        ),
                      ),
                    if (!hasImage)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              widget.collageManager.cornerRadius,
                            ),
                            border: Border.all(
                              color: placeholderBorderColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    if (!hasImage)
                      Center(
                        child: GestureDetector(
                          onTap: () => _addPhotoToBox(context),
                          child: Icon(
                            Icons.add_a_photo,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                        ),
                      ),

                    // Smart border overlay (ignore pointer so it doesn't block interactions)
                    if (widget.hasGlobalBorder && widget.globalBorderWidth > 0)
                      IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            widget.collageManager.cornerRadius,
                          ),
                          child: SmartBorderOverlay(
                            box: box,
                            borderWidth: widget.globalBorderWidth,
                            borderColor: widget.globalBorderColor,
                            otherBoxes: widget.otherBoxes,
                          ),
                        ),
                      ),

                    // Action buttons (only for selected boxes)
                    if (widget.isSelected)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: GestureDetector(
                            onPanStart: _onRotationHandleStart,
                            onPanUpdate: _onRotationHandleUpdate,
                            onPanEnd: _onRotationHandleEnd,
                            onPanCancel: _onRotationHandleCancel,
                            behavior: HitTestBehavior.opaque,
                            child: _buildActionIcon(Icons.rotate_right),
                          ),
                        ),
                      ),
                    if (widget.isSelected)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: FittedBox(
                          fit: BoxFit
                              .scaleDown, // Prevent overflow on very small boxes
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: widget.onDelete,
                                behavior: HitTestBehavior.opaque,
                                child: _buildActionIcon(Icons.delete_outline),
                              ),
                              if (box.imageFile != null) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _showPhotoEditor(context),
                                  behavior: HitTestBehavior.opaque,
                                  child: _buildActionIcon(Icons.edit),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_showRotationSnapGuides)
              Positioned.fill(
                child: IgnorePointer(
                  child: _RotationSnapGuides(angle: _snapGuideAngle),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    widget.box.rotationBaseRadians = widget.box.rotationRadians;
    _rotationActive = false;
    _resetRotationTracking();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.isSelected) return;

    final pointerCount = details.pointerCount;
    if (pointerCount == 1 && !_rotationActive) {
      widget.onPanUpdate(
        DragUpdateDetails(
          delta: details.focalPointDelta,
          globalPosition: details.focalPoint,
          localPosition: details.localFocalPoint,
        ),
      );
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_rotationActive) {
      // Rotation handle will manage cleanup when gesture ends.
      return;
    }
    widget.box.rotationBaseRadians = widget.box.rotationRadians;
  }

  void _onRotationHandleStart(DragStartDetails details) {
    _rotationActive = true;
    _rotationStartAngle = widget.box.rotationRadians;
    _rotationHandleStartGlobal = details.globalPosition;
    widget.box.rotationBaseRadians = widget.box.rotationRadians;
    widget.onRotateActive?.call(true);
    widget.collageManager.setSnappingSuspended(true);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset centerLocal = renderBox.size.center(Offset.zero);
      _boxCenterGlobal = renderBox.localToGlobal(centerLocal);
      _rotationStartPointerAngle = _pointerAngle(details.globalPosition);
    } else {
      _boxCenterGlobal = null;
      _rotationStartPointerAngle = null;
    }
  }

  void _onRotationHandleUpdate(DragUpdateDetails details) {
    if (!_rotationActive) {
      return;
    }
    double newAngle = _computeRotationFromDrag(details.globalPosition);
    newAngle = _applyRotationSnapping(newAngle);
    if (newAngle != widget.box.rotationRadians) {
      widget.box.rotationRadians = newAngle;
      widget.collageManager.clampBoxToTemplate(widget.box);
      widget.collageManager.refresh();
    }
  }

  void _onRotationHandleEnd(DragEndDetails details) {
    _finishRotationHandleGesture();
  }

  void _onRotationHandleCancel() {
    _finishRotationHandleGesture();
  }

  void _finishRotationHandleGesture() {
    if (!_rotationActive) {
      return;
    }
    _rotationActive = false;
    widget.onRotateActive?.call(false);
    widget.collageManager.setSnappingSuspended(false);
    widget.box.rotationBaseRadians = widget.box.rotationRadians;
    _clearRotationSnapGuides();
    _resetRotationTracking();
  }

  Widget _buildActionIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 25,
        color: Colors.white,
      ),
    );
  }

  double _computeRotationFromDrag(Offset globalPosition) {
    final double? startPointerAngle = _rotationStartPointerAngle;
    final Offset? center = _boxCenterGlobal;
    if (startPointerAngle != null && center != null) {
      final double currentPointerAngle = _pointerAngle(globalPosition);
      final double angleDelta =
          _normalizeAngle(currentPointerAngle - startPointerAngle);
      return _normalizeAngle(_rotationStartAngle + angleDelta);
    }

    const double fallbackSensitivity = 0.006; // radians per logical pixel
    final Offset? startGlobal = _rotationHandleStartGlobal;
    final double displacementX = startGlobal != null
        ? globalPosition.dx - startGlobal.dx
        : 0.0;
    return _normalizeAngle(
      _rotationStartAngle + displacementX * fallbackSensitivity,
    );
  }

  double _pointerAngle(Offset globalPosition) {
    final Offset? center = _boxCenterGlobal;
    if (center == null) return 0.0;
    final Offset vector = globalPosition - center;
    return math.atan2(vector.dy, vector.dx);
  }

  void _resetRotationTracking() {
    _rotationStartPointerAngle = null;
    _boxCenterGlobal = null;
    _rotationHandleStartGlobal = null;
    _rotationStartAngle = widget.box.rotationRadians;
  }

  double _applyRotationSnapping(double angle) {
    const double snapIncrement = math.pi / 4; // 45° steps
    const double snapTolerance = math.pi / 36; // 5° tolerance

    final double normalized = _normalizeAngle(angle);
    final double snappedMultiple = (normalized / snapIncrement).roundToDouble();
    final double snappedAngle = snappedMultiple * snapIncrement;

    if ((normalized - snappedAngle).abs() <= snapTolerance) {
      _updateRotationSnapGuides(snappedAngle);
      return _normalizeAngle(snappedAngle);
    }

    _clearRotationSnapGuides();
    return normalized;
  }

  double _normalizeAngle(double angle) {
    const double twoPi = 2 * math.pi;
    angle = angle % twoPi;
    if (angle <= -math.pi) {
      angle += twoPi;
    } else if (angle > math.pi) {
      angle -= twoPi;
    }
    return angle;
  }

  void _updateRotationSnapGuides(double targetAngle) {
    final double normalized = _normalizeAngle(targetAngle);
    if (_showRotationSnapGuides &&
        (_snapGuideAngle - normalized).abs() <= 1e-4) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _showRotationSnapGuides = true;
      _snapGuideAngle = normalized;
    });
  }

  void _clearRotationSnapGuides() {
    if (!_showRotationSnapGuides) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _showRotationSnapGuides = false;
    });
  }

  /// Add photo to this specific box
  void _addPhotoToBox(BuildContext context) async {
    if (widget.onAddPhoto != null) {
      await widget.onAddPhoto!();
    }
  }

  /// Show photo editor modal
  void _showPhotoEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoEditorPage(
          photoBox: widget.box,
          onPhotoChanged: widget.onPhotoModified,
        ),
      ),
    );
  }
}

/// Decorates the photo box frame so the outer shadow respects rounded corners.
BoxDecoration _frameDecoration({
  required double cornerRadius,
  required double intensity,
  required Color frameColor,
  required bool isDarkMode,
}) {
  return BoxDecoration(
    color: frameColor,
    borderRadius: BorderRadius.circular(cornerRadius),
    boxShadow: _shadowLayers(
      intensity,
      isDarkMode: isDarkMode,
    ),
  );
}

/// Build layered shadows for a crisper 3D-like effect without a dull halo.
List<BoxShadow>? _shadowLayers(double intensity, {required bool isDarkMode}) {
  if (intensity <= 0) return null;

  // Normalize to 0..1 based on current slider range (0..14)
  final double t = (intensity.clamp(0.0, 14.0)) / 14.0;

  final double dropOpacity = isDarkMode
      ? 0.32 + 0.18 * t
      : 0.18 + 0.16 * t;
  final double dropBlur = 18 + 14 * t; // 18..32
  final double dropOffsetY = 8 + 6 * t; // 8..14

  final double rimOpacity = isDarkMode
      ? 0.22 + 0.12 * t
      : 0.10 + 0.05 * t;
  final double rimBlur = 10 + 8 * t; // 10..22
  final double rimOffsetY = 3 + 3 * t; // 3..6

  final double highlightOpacity = isDarkMode
      ? 0.16 + 0.08 * t
      : 0.35 + 0.25 * t;
  final double highlightBlur = 8 + 8 * t; // 8..22
  final double highlightOffsetY = -(2 + 2 * t); // -2..-4

  return [
    BoxShadow(
      color: Colors.white.withValues(alpha: highlightOpacity),
      blurRadius: highlightBlur,
      offset: Offset(0, highlightOffsetY),
      spreadRadius: -2 - t,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: rimOpacity),
      blurRadius: rimBlur,
      offset: Offset(0, rimOffsetY),
      spreadRadius: -1.5,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: dropOpacity),
      blurRadius: dropBlur,
      offset: Offset(0, dropOffsetY),
    ),
  ];
}

class _RotationSnapGuides extends StatelessWidget {
  final double angle;

  const _RotationSnapGuides({required this.angle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 1.3,
        heightFactor: 1.3,
        child: CustomPaint(
          painter: _RotationSnapGuidesPainter(angle: angle),
        ),
      ),
    );
  }
}

class _RotationSnapGuidesPainter extends CustomPainter {
  final double angle;

  const _RotationSnapGuidesPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double length = size.longestSide;
    final double halfLength = length * 0.5;

    final Offset axis = Offset(math.cos(angle), math.sin(angle));
    final Offset perp = Offset(-axis.dy, axis.dx);

    final Paint glowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final Paint mainLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final Paint secondaryLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final Offset mainStart = center - axis * halfLength;
    final Offset mainEnd = center + axis * halfLength;
    final Offset perpStart = center - perp * halfLength;
    final Offset perpEnd = center + perp * halfLength;

    canvas.drawLine(mainStart, mainEnd, glowPaint);
    canvas.drawLine(mainStart, mainEnd, mainLinePaint);

    canvas.drawLine(perpStart, perpEnd, glowPaint);
    canvas.drawLine(perpStart, perpEnd, secondaryLinePaint);
  }

  @override
  bool shouldRepaint(covariant _RotationSnapGuidesPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
