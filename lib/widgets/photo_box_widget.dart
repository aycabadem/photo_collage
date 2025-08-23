import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../widgets/smart_border_overlay.dart';

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

  /// Global border settings from CollageManager
  final double globalBorderWidth;
  final Color globalBorderColor;
  final bool hasGlobalBorder;

  /// Other photo boxes for smart border detection
  final List<PhotoBox> otherBoxes;

  const PhotoBoxWidget({
    super.key,
    required this.box,
    required this.isSelected,
    required this.onTap,
    required this.onPanUpdate,
    required this.onDelete,
    this.onAddPhoto,
    required this.globalBorderWidth,
    required this.globalBorderColor,
    required this.hasGlobalBorder,
    required this.otherBoxes,
  });

  @override
  Widget build(BuildContext context) {
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
            // No border here - we'll draw it manually for smart rendering
          ),
          child: Stack(
            children: [
              // Photo or placeholder
              box.imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        box.imageFile!,
                        fit: box.imageFit, // Box'tan gelen fit seçeneği
                        width: box.size.width,
                        height: box.size.height,
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

                // Fit options button (only when photo exists)
                if (box.imageFile != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showFitOptions(context),
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
                          Icons.fit_screen,
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
    );
  }

  /// Add photo to this specific box
  void _addPhotoToBox(BuildContext context) async {
    if (onAddPhoto != null) {
      await onAddPhoto!();
    }
  }

  /// Show fit options popup menu
  void _showFitOptions(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        box.position.dx + box.size.width,
        box.position.dy,
        box.position.dx + box.size.width + 200,
        box.position.dy + 200,
      ),
      items: [
        PopupMenuItem(
          value: BoxFit.cover,
          child: Row(
            children: [
              Icon(Icons.crop_square, size: 16),
              SizedBox(width: 8),
              Text('Cover (Tam Doldur)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: BoxFit.contain,
          child: Row(
            children: [
              Icon(Icons.fit_screen, size: 16),
              SizedBox(width: 8),
              Text('Contain (Sığdır)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: BoxFit.fill,
          child: Row(
            children: [
              Icon(Icons.aspect_ratio, size: 16),
              SizedBox(width: 8),
              Text('Fill (Uzat)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: BoxFit.fitWidth,
          child: Row(
            children: [
              Icon(Icons.width_normal, size: 16),
              SizedBox(width: 8),
              Text('Fit Width (Genişliğe Sığdır)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: BoxFit.fitHeight,
          child: Row(
            children: [
              Icon(Icons.height, size: 16),
              SizedBox(width: 8),
              Text('Fit Height (Yüksekliğe Sığdır)'),
            ],
          ),
        ),
      ],
    ).then((selectedFit) {
      if (selectedFit != null) {
        box.imageFit = selectedFit;
        // Notify parent to rebuild
        if (onAddPhoto != null) {
          // Trigger a rebuild by calling a callback
          onAddPhoto!();
        }
      }
    });
  }
}
