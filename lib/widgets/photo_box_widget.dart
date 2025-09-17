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
  double _rotationGestureBase = 0.0;
  bool _rotationActive = false;

  @override
  Widget build(BuildContext context) {
    final box = widget.box;

    return GestureDetector(
      onDoubleTap: widget.onTap, // Double tap to select
      onScaleStart: widget.isSelected ? _handleScaleStart : null,
      onScaleUpdate: widget.isSelected ? _handleScaleUpdate : null,
      onScaleEnd: widget.isSelected ? _handleScaleEnd : null,
      behavior: HitTestBehavior.opaque, // Prevent background taps
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.collageManager.cornerRadius),
          // Layered shadows for stronger 3D effect
          boxShadow: _shadowLayers(widget.collageManager.shadowIntensity),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.collageManager.cornerRadius),
          child: Stack(
            children: [
              // Photo or placeholder
              box.imageFile != null
                  ? Transform.translate(
                      // Subtle lift for 3D feel; increases slightly with shadow intensity
                      offset: Offset(
                        0,
                        -(_liftOffset(widget.collageManager.shadowIntensity)),
                      ),
                      child: Transform.scale(
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
                    )
                  : Container(
                      color: Colors.transparent,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _addPhotoToBox(context),
                          child: Icon(
                            Icons.add_a_photo,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
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
                    fit: BoxFit.scaleDown, // Prevent overflow on very small boxes
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Delete (plain white icon, no background)
                        GestureDetector(
                          onTap: widget.onDelete,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.delete_outline,
                              size: 25,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Edit (only when photo exists)
                        if (box.imageFile != null)
                          GestureDetector(
                            onTap: () => _showPhotoEditor(context),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.edit,
                                size: 25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _rotationGestureBase = widget.box.rotationRadians;
    widget.box.rotationBaseRadians = widget.box.rotationRadians;
    _rotationActive = false;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.isSelected) return;

    final pointerCount = details.pointerCount;
    if (pointerCount >= 2) {
      if (!_rotationActive) {
        _rotationActive = true;
        _rotationGestureBase = widget.box.rotationRadians;
        widget.box.rotationBaseRadians = widget.box.rotationRadians;
        widget.onRotateActive?.call(true);
        widget.collageManager.setSnappingSuspended(true);
      }
      final newAngle = _normalizeAngle(_rotationGestureBase + details.rotation);
      if (widget.box.rotationRadians != newAngle) {
        widget.box.rotationRadians = newAngle;
        widget.collageManager.clampBoxToTemplate(widget.box);
        widget.collageManager.refresh();
      }
    } else if (pointerCount == 1) {
      if (_rotationActive) {
        _rotationActive = false;
        widget.onRotateActive?.call(false);
        widget.collageManager.setSnappingSuspended(false);
      }
      widget.onPanUpdate(
        DragUpdateDetails(
          delta: details.focalPointDelta,
          globalPosition: details.focalPoint,
          localPosition: details.localFocalPoint,
        ),
      );
    } else {
      if (_rotationActive) {
        _rotationActive = false;
        widget.onRotateActive?.call(false);
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_rotationActive) {
      _rotationActive = false;
      widget.onRotateActive?.call(false);
      widget.collageManager.setSnappingSuspended(false);
    }
    widget.box.rotationBaseRadians = widget.box.rotationRadians;
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
        builder: (_) =>
            PhotoEditorPage(photoBox: widget.box, onPhotoChanged: widget.onPhotoModified),
      ),
    );
  }
}

/// Build layered shadows for a stronger, more 3D-like effect
List<BoxShadow>? _shadowLayers(double intensity) {
  if (intensity <= 0) return null;

  // Normalize to 0..1 based on current slider range (0..14)
  final double t = (intensity.clamp(0.0, 14.0)) / 14.0;

  // Cleaner, less smoky shadows: no spread, moderate blur, lower alpha
  final ambientShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05 + 0.05 * t), // 0.05..0.10
    blurRadius: 12 + 8 * t, // 12..20
    offset: Offset(0, 2 + 2 * t), // 2..4
    spreadRadius: 0,
  );

  final keyShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.15 + 0.10 * t), // 0.15..0.25
    blurRadius: 8 + 12 * t, // 8..20
    offset: Offset(0, 4 + 6 * t), // 4..10
    spreadRadius: 0,
  );

  return [ambientShadow, keyShadow];
}

// Compute a subtle lift offset for the image based on shadow intensity
double _liftOffset(double intensity) {
  if (intensity <= 0) return 0;
  final double t = (intensity.clamp(0.0, 14.0)) / 14.0;
  // 0.0 .. 3.0 px upward
  return 1.0 + 2.0 * t;
}
