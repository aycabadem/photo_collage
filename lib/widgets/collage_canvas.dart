import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../widgets/photo_box_widget.dart';
import '../widgets/resize_handle_widget.dart';

/// Widget for the main collage canvas with photo boxes and interaction
class CollageCanvas extends StatelessWidget {
  /// Size of the template
  final Size templateSize;

  /// List of photo boxes to display
  final List<PhotoBox> photoBoxes;

  /// Currently selected photo box
  final PhotoBox? selectedBox;

  /// Callback when a photo box is tapped
  final ValueChanged<PhotoBox> onBoxSelected;

  /// Callback when a photo box is dragged
  final void Function(PhotoBox, DragUpdateDetails) onBoxDragged;

  /// Callback when a photo box is deleted
  final ValueChanged<PhotoBox> onBoxDeleted;

  /// Callback when resize handles are dragged
  final Function(PhotoBox, double, double) onResizeHandleDragged;

  /// Callback when tapping outside boxes (deselection)
  final VoidCallback onBackgroundTap;

  const CollageCanvas({
    super.key,
    required this.templateSize,
    required this.photoBoxes,
    required this.selectedBox,
    required this.onBoxSelected,
    required this.onBoxDragged,
    required this.onBoxDeleted,
    required this.onResizeHandleDragged,
    required this.onBackgroundTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (details) {
        // Only deselect if tapping on empty background area
        bool tappedOnBox = false;
        for (final box in photoBoxes) {
          final boxRect = Rect.fromLTWH(
            box.position.dx,
            box.position.dy,
            box.size.width,
            box.size.height,
          );
          if (boxRect.contains(details.localPosition)) {
            tappedOnBox = true;
            break;
          }
        }

        if (!tappedOnBox) {
          onBackgroundTap();
        }
      },
      child: Container(
        width: templateSize.width,
        height: templateSize.height,
        decoration: BoxDecoration(
          color: Colors.grey[100], // Lighter, more modern color
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Photo boxes
            for (var box in photoBoxes) _buildPhotoBox(box),

            // Overlay for selected box (resize handles)
            if (selectedBox != null) _buildOverlay(selectedBox!),
          ],
        ),
      ),
    );
  }

  /// Build individual photo box widget
  Widget _buildPhotoBox(PhotoBox box) {
    // Simple check: is box inside template?
    if (box.position.dx < 0 ||
        box.position.dy < 0 ||
        box.position.dx + box.size.width > templateSize.width ||
        box.position.dy + box.size.height > templateSize.height) {
      return const SizedBox.shrink(); // Hide boxes outside template
    }

    return PhotoBoxWidget(
      box: box,
      isSelected: selectedBox == box,
      onTap: () => onBoxSelected(box),
      onPanUpdate: (details) => onBoxDragged(box, details),
      onDelete: () => onBoxDeleted(box),
    );
  }

  /// Build overlay with resize handles for selected box
  Widget _buildOverlay(PhotoBox box) {
    double handleSize = 16.0;
    return Stack(
      children: [
        // Top-left resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.topLeft,
          size: handleSize,
          onDrag: (dx, dy) => onResizeHandleDragged(box, dx, dy),
        ),

        // Top-right resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.topRight,
          size: handleSize,
          onDrag: (dx, dy) => onResizeHandleDragged(box, dx, dy),
        ),

        // Bottom-left resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.bottomLeft,
          size: handleSize,
          onDrag: (dx, dy) => onResizeHandleDragged(box, dx, dy),
        ),

        // Bottom-right resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.bottomRight,
          size: handleSize,
          onDrag: (dx, dy) => onResizeHandleDragged(box, dx, dy),
        ),
      ],
    );
  }
}
