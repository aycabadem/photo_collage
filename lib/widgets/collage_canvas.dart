import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../models/alignment_guideline.dart';
import '../widgets/photo_box_widget.dart';
import '../widgets/resize_handle_widget.dart';
import '../widgets/guidelines_overlay.dart';
import '../services/collage_manager.dart';

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

  /// Callback when add photo to box is requested
  final Future<void> Function(PhotoBox) onAddPhotoToBox;

  /// Callback when resize handles are dragged
  final Function(PhotoBox, double, double, Alignment) onResizeHandleDragged;

  /// Callback when tapping outside boxes (deselection)
  final VoidCallback onBackgroundTap;

  /// List of alignment guidelines to display
  final List<AlignmentGuideline> guidelines;

  final CollageManager collageManager;

  const CollageCanvas({
    super.key,
    required this.templateSize,
    required this.photoBoxes,
    required this.selectedBox,
    required this.onBoxSelected,
    required this.onBoxDragged,
    required this.onBoxDeleted,
    required this.onAddPhotoToBox,
    required this.onResizeHandleDragged,
    required this.onBackgroundTap,
    this.guidelines = const [],
    required this.collageManager,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Deselect when tapping on empty background area
        // Only deselect if no photo box is tapped
        onBackgroundTap();
      },
      child: Container(
        width: templateSize.width,
        height: templateSize.height,
        decoration: BoxDecoration(
          color: collageManager.backgroundColorWithOpacity,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Photo boxes (bottom layer)
            for (var box in photoBoxes) _buildPhotoBox(box),

            // Overlay for selected box (resize handles)
            if (selectedBox != null) _buildOverlay(selectedBox!),

            // Guidelines overlay (top layer, but IgnorePointer)
            if (guidelines.isNotEmpty)
              GuidelinesOverlay(
                guidelines: guidelines,
                templateSize: templateSize,
              ),
          ],
        ),
      ),
    );
  }

  /// Build individual photo box widget
  Widget _buildPhotoBox(PhotoBox box) {
    return PhotoBoxWidget(
      box: box,
      isSelected: selectedBox == box,
      onTap: () => onBoxSelected(box),
      onPanUpdate: (details) => onBoxDragged(box, details),
      onDelete: () => onBoxDeleted(box),
      onAddPhoto: () async => await onAddPhotoToBox(box),
      onPhotoModified: () {
        // Notify CollageManager that photo has been modified
        // This will trigger UI updates to show new pan/zoom values
        collageManager.notifyListeners();
      },
      globalBorderWidth: collageManager.globalBorderWidth,
      globalBorderColor: collageManager.globalBorderColor,
      hasGlobalBorder: collageManager.hasGlobalBorder,
      otherBoxes: photoBoxes.where((b) => b != box).toList(),
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
          onDrag: (dx, dy) =>
              onResizeHandleDragged(box, dx, dy, Alignment.topLeft),
        ),

        // Top-right resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.topRight,
          size: handleSize,
          onDrag: (dx, dy) =>
              onResizeHandleDragged(box, dx, dy, Alignment.topRight),
        ),

        // Bottom-left resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.bottomLeft,
          size: handleSize,
          onDrag: (dx, dy) =>
              onResizeHandleDragged(box, dx, dy, Alignment.bottomLeft),
        ),

        // Bottom-right resize handle
        ResizeHandleWidget(
          box: box,
          alignment: Alignment.bottomRight,
          size: handleSize,
          onDrag: (dx, dy) =>
              onResizeHandleDragged(box, dx, dy, Alignment.bottomRight),
        ),
      ],
    );
  }
}
