import 'package:flutter/material.dart';
import '../models/photo_box.dart';

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

  const PhotoBoxWidget({
    super.key,
    required this.box,
    required this.isSelected,
    required this.onTap,
    required this.onPanUpdate,
    required this.onDelete,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.9),
                blurRadius: 1,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
            border: isSelected
                ? Border.all(
                    color: Colors.amber[600]!, // More vibrant selection color
                    width: 3,
                    style: BorderStyle.solid,
                  )
                : Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Stack(
            children: [
              // Photo or placeholder
              box.imageFile != null
                  ? Image.file(
                      box.imageFile!,
                      fit: BoxFit.cover,
                      width: box.size.width,
                      height: box.size.height,
                    )
                  : Container(
                      color: Colors.blue[300],
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),

              // Delete button (only for selected boxes)
              if (isSelected)
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
            ],
          ),
        ),
      ),
    );
  }
}
