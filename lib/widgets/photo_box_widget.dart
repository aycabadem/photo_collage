import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../widgets/smart_border_overlay.dart';
import '../widgets/photo_editor_modal.dart';
import '../services/collage_manager.dart';

/// Widget for displaying a single photo box in the collage
class PhotoBoxWidget extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    // Debug: Print current photo box values
    // Debug prints removed for production cleanliness

    return GestureDetector(
      onDoubleTap: onTap, // Double tap to select
      onPanUpdate: isSelected
          ? onPanUpdate
          : null, // Only allow dragging when selected
      behavior: HitTestBehavior.opaque, // Prevent background taps
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(collageManager.cornerRadius),
          // Layered shadows for stronger 3D effect
          boxShadow: _shadowLayers(collageManager.shadowIntensity),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(collageManager.cornerRadius),
          child: Stack(
            children: [
              // Photo or placeholder
              box.imageFile != null
                  ? Transform.scale(
                      scale: box.photoScale,
                      alignment: box.alignment,
                      child: Image.file(
                        box.imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: box.alignment,
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
              if (hasGlobalBorder && globalBorderWidth > 0)
                IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      collageManager.cornerRadius,
                    ),
                    child: SmartBorderOverlay(
                      box: box,
                      borderWidth: globalBorderWidth,
                      borderColor: globalBorderColor,
                      otherBoxes: otherBoxes,
                    ),
                  ),
                ),

              // Action buttons (only for selected boxes)
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Delete (plain white icon, no background)
                      GestureDetector(
                        onTap: onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.delete_outline,
                            size: 24,
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
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.edit,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Add photo to this specific box
  void _addPhotoToBox(BuildContext context) async {
    if (onAddPhoto != null) {
      await onAddPhoto!();
    }
  }

  /// Show photo editor modal
  void _showPhotoEditor(BuildContext context) {
    // Update alignment based on current photo display

    // Debug: Print photo state BEFORE opening modal
    // Debug prints removed

    showDialog(
      context: context,
      builder: (context) =>
          PhotoEditorModal(photoBox: box, onPhotoChanged: onPhotoModified),
    );
  }

  /// Update photo alignment to show the current visible part
}

/// Build layered shadows for a stronger, more 3D-like effect
List<BoxShadow>? _shadowLayers(double intensity) {
  if (intensity <= 0) return null;

  // Normalize to 0..1 based on current slider range (0..14)
  final double t = (intensity.clamp(0.0, 14.0)) / 14.0;

  // Key shadow: prominent but tighter to the card
  final keyShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.22 + 0.18 * t), // 0.22..0.40
    blurRadius: 10 + 22 * t, // 10..32
    offset: Offset(0, 6 + 10 * t), // 6..16
    spreadRadius: 0.2 + 0.8 * t, // 0.2..1.0 (reduced spread to avoid greying)
  );

  // Ambient shadow: softer, low opacity, minimal spread (reduces background greying)
  final ambientShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06 + 0.10 * t), // 0.06..0.16
    blurRadius: 18 + 22 * t, // 18..40
    offset: Offset(0, 2 + 4 * t), // 2..6
    spreadRadius: 0.0 + 1.5 * t, // 0..1.5
  );

  // Deep shadow only at higher intensities, still restrained
  if (t > 0.7) {
    final double u = (t - 0.7) / 0.3; // 0..1 for top 30%
    final deepShadow = BoxShadow(
      color: Colors.black.withValues(alpha: 0.10 + 0.14 * u), // 0.10..0.24
      blurRadius: 30 + 24 * u, // 30..54
      offset: Offset(0, 8 + 8 * u), // 8..16
      spreadRadius: 0.0 + 1.0 * u, // 0..1.0
    );
    return [ambientShadow, keyShadow, deepShadow];
  }

  return [ambientShadow, keyShadow];
}
