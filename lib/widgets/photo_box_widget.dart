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
    if (box.imageFile != null) {
      print('🔍 DEBUG - PhotoBoxWidget BUILD:');
      print('PhotoBox Alignment: ${box.alignment}');
      print('PhotoBox Size: ${box.size}');
      print('PhotoBox Scale: ${box.photoScale}');
      print('PhotoBox Offset: ${box.photoOffset}');
    }

    return Positioned(
      left: box.position.dx,
      top: box.position.dy,
      child: GestureDetector(
        onDoubleTap: onTap, // Double tap to select
        onPanUpdate: isSelected
            ? onPanUpdate
            : null, // Only allow dragging when selected
        behavior: HitTestBehavior.opaque, // Prevent background taps
        child: Container(
          width: box.size.width,
          height: box.size.height,
          decoration: BoxDecoration(
            // No radius here - only shadow
            boxShadow: collageManager.shadowIntensity > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: collageManager.shadowIntensity,
                      offset: Offset(
                        collageManager.shadowIntensity * 0.5,
                        collageManager.shadowIntensity * 0.5,
                      ),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(collageManager.cornerRadius),
            child: Stack(
              children: [
                // Photo or placeholder
                box.imageFile != null
                    ? Transform.scale(
                        scale: box.photoScale,
                        child: Image.file(
                          box.imageFile!,
                          fit: BoxFit.cover,
                          width: box.size.width,
                          height: box.size.height,
                          alignment: box.alignment,
                        ),
                      )
                    : Container(
                        color: Colors.blue[300],
                        child: Center(
                          child: GestureDetector(
                            onTap: () => _addPhotoToBox(context),
                            child: const Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                // Smart border overlay (ignore pointer so it doesn't block interactions)
                if (hasGlobalBorder && globalBorderWidth > 0)
                  IgnorePointer(
                    child: SmartBorderOverlay(
                      box: box,
                      borderWidth: globalBorderWidth,
                      borderColor: globalBorderColor,
                      otherBoxes: otherBoxes,
                    ),
                  ),

                // Action buttons (only for selected boxes)
                if (isSelected) ...[
                  // Delete button
                  Positioned(
                    top: 4,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Edit button (only when photo exists)
                  if (box.imageFile != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _showPhotoEditor(context),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
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
    _updatePhotoAlignment();

    // Debug: Print photo state BEFORE opening modal
    print('🔍 DEBUG - BEFORE Opening Modal:');
    print('PhotoBox Alignment: ${box.alignment}');
    print('PhotoBox Size: ${box.size}');
    print('PhotoBox Scale: ${box.photoScale}');
    print('PhotoBox Offset: ${box.photoOffset}');

    showDialog(
      context: context,
      builder: (context) =>
          PhotoEditorModal(photoBox: box, onPhotoChanged: onPhotoModified),
    );
  }

  /// Update photo alignment to show the current visible part
  void _updatePhotoAlignment() {
    // Calculate alignment based on current photo display
    // This ensures the modal shows the same part of the photo
    if (box.imageFile != null) {
      // Calculate alignment based on current photo position
      // Since the photo is currently showing the center, set alignment to center
      // But we need to calculate this based on actual photo content

      // For now, let's try to detect if the photo has been moved
      // If photoOffset is not zero, calculate alignment from it
      if (box.photoOffset != Offset.zero) {
        // Convert photoOffset to alignment
        final boxSize = box.size;
        final maxOffsetX = boxSize.width / 2;
        final maxOffsetY = boxSize.height / 2;

        final alignmentX = (box.photoOffset.dx / maxOffsetX).clamp(-1.0, 1.0);
        final alignmentY = (box.photoOffset.dy / maxOffsetY).clamp(-1.0, 1.0);

        box.alignment = Alignment(alignmentX, alignmentY);
        print('🔍 DEBUG - Calculated Alignment from Offset: ${box.alignment}');
      } else {
        // If no offset, keep center alignment
        box.alignment = Alignment.center;
        print('🔍 DEBUG - Kept Center Alignment');
      }

      print('🔍 DEBUG - Final PhotoBox Alignment: ${box.alignment}');
    }
  }
}
