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
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // Deselect when tapping on empty background area
          // Only deselect if no photo box is tapped
          onBackgroundTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
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
      ),
    );
  }

  /// Build individual photo box widget with margin applied
  Widget _buildPhotoBox(PhotoBox box) {
    // Calculate margin-adjusted size and position
    final margin = collageManager.photoMargin;

    // Reduce photo size to accommodate margin
    final adjustedWidth = box.size.width - (margin * 2);
    final adjustedHeight = box.size.height - (margin * 2);

    // Adjust position to center the photo within its original space
    final adjustedLeft = box.position.dx + margin;
    final adjustedTop = box.position.dy + margin;

    return Positioned(
      left: adjustedLeft,
      top: adjustedTop,
      child: SizedBox(
        width: adjustedWidth,
        height: adjustedHeight,
        child: PhotoBoxWidget(
          box: box,
          isSelected: selectedBox == box,
          onTap: () => onBoxSelected(box),
          onPanUpdate: (details) => onBoxDragged(box, details),
          onDelete: () => onBoxDeleted(box),
          onAddPhoto: () async => await onAddPhotoToBox(box),
          onPhotoModified: () {
            collageManager.refresh();
          },
          globalBorderWidth: collageManager.globalBorderWidth,
          globalBorderColor: collageManager.globalBorderColor,
          hasGlobalBorder: collageManager.hasGlobalBorder,
          otherBoxes: photoBoxes.where((b) => b != box).toList(),
          collageManager: collageManager,
        ),
      ),
    );
  }

  /// Build overlay for selected box with margin applied
  Widget _buildOverlay(PhotoBox box) {
    // Apply same margin logic to overlay
    final margin = collageManager.photoMargin;

    final adjustedWidth = box.size.width - (margin * 2);
    final adjustedHeight = box.size.height - (margin * 2);
    final adjustedLeft = box.position.dx + margin;
    final adjustedTop = box.position.dy + margin;

    return Positioned(
      left: adjustedLeft,
      top: adjustedTop,
      child: SizedBox(
        width: adjustedWidth,
        height: adjustedHeight,
        child: Stack(
          children: [
            // Top-left resize handle
            ResizeHandleWidget(
              box: box,
              alignment: Alignment.topLeft,
              size: 16.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.topLeft),
            ),

            // Top-right resize handle
            ResizeHandleWidget(
              box: box,
              alignment: Alignment.topRight,
              size: 16.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.topRight),
            ),

            // Bottom-left resize handle
            ResizeHandleWidget(
              box: box,
              alignment: Alignment.bottomLeft,
              size: 16.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.bottomLeft),
            ),

            // Bottom-right resize handle
            ResizeHandleWidget(
              box: box,
              alignment: Alignment.bottomRight,
              size: 16.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.bottomRight),
            ),
          ],
        ),
      ),
    );
  }
}
