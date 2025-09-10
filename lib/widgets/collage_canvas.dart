import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../models/alignment_guideline.dart';
import '../widgets/photo_box_widget.dart';
import '../widgets/resize_handle_widget.dart';
import '../widgets/guidelines_overlay.dart';
import '../services/collage_manager.dart';
import '../models/background.dart';
import 'dart:math' as math;

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
    this.animateSize = true,
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
        child: animateSize
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: templateSize.width,
                height: templateSize.height,
                decoration: _decoration(),
                child: _contentStack(context),
              )
            : Container(
                width: templateSize.width,
                height: templateSize.height,
                decoration: _decoration(),
                child: _contentStack(context),
              ),
      ),
    );
  }

  final bool animateSize;

  BoxDecoration _decoration() => BoxDecoration(
        gradient: collageManager.backgroundMode == BackgroundMode.gradient
            ? LinearGradient(
                begin:
                    _beginFromAngle(collageManager.backgroundGradient.angleDeg),
                end: _endFromAngle(collageManager.backgroundGradient.angleDeg),
                colors: collageManager.gradientColorsWithOpacity,
                stops: collageManager.gradientStops,
              )
            : null,
        color: collageManager.backgroundMode == BackgroundMode.solid
            ? collageManager.backgroundColorWithOpacity
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 2,
          ),
        ],
      );

  Widget _contentStack(BuildContext context) => Padding(
        padding: EdgeInsets.all(collageManager.outerMargin),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            for (var box in photoBoxes) _buildPhotoBox(box, context),
            if (selectedBox != null) _buildOverlay(selectedBox!, context),
            if (guidelines.isNotEmpty)
              GuidelinesOverlay(
                guidelines: guidelines,
                templateSize: templateSize,
              ),
          ],
        ),
      );

  /// Build individual photo box widget with inner/outer margins applied
  Widget _buildPhotoBox(PhotoBox box, BuildContext context) {
    // Outer margin: uniformly scale (preserve aspect) then center to create equal frame on all sides
    final double outer = collageManager.outerMargin;
    double s = 1.0;
    if (outer > 0) {
      final double sx = (templateSize.width - 2 * outer) / templateSize.width;
      final double sy = (templateSize.height - 2 * outer) / templateSize.height;
      s = math.min(sx, sy);
    }
    final double marginX = (templateSize.width - templateSize.width * s) / 2;
    final double marginY = (templateSize.height - templateSize.height * s) / 2;

    double baseLeft = marginX + box.position.dx * s;
    double baseTop = marginY + box.position.dy * s;
    double baseWidth = box.size.width * s;
    double baseHeight = box.size.height * s;

    // Inner margin: apply only between photos (edge-aware), not on outer edges
    final double inner = collageManager.innerMargin;
    final double half = inner * 0.5;
    const double eps = 0.5; // edge tolerance in logical px
    final bool isLeftEdge = box.position.dx <= eps;
    final bool isRightEdge = (box.position.dx + box.size.width) >= (templateSize.width - eps);
    final bool isTopEdge = box.position.dy <= eps;
    final bool isBottomEdge = (box.position.dy + box.size.height) >= (templateSize.height - eps);

    final double leftInset = isLeftEdge ? 0.0 : half;
    final double rightInset = isRightEdge ? 0.0 : half;
    final double topInset = isTopEdge ? 0.0 : half;
    final double bottomInset = isBottomEdge ? 0.0 : half;

    double adjustedLeft = baseLeft + leftInset;
    double adjustedTop = baseTop + topInset;
    double adjustedWidth = baseWidth - (leftInset + rightInset);
    double adjustedHeight = baseHeight - (topInset + bottomInset);

    // Pixel-snap for symmetry across columns/rows
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    double snap(double v) => (v * dpr).round() / dpr;
    adjustedLeft = snap(adjustedLeft);
    adjustedTop = snap(adjustedTop);
    adjustedWidth = snap(adjustedWidth);
    adjustedHeight = snap(adjustedHeight);

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

  /// Build overlay for selected box with inner/outer margins applied
  Widget _buildOverlay(PhotoBox box, BuildContext context) {
    // Outer scaling same as for the box (uniform scale + centered)
    final double outer = collageManager.outerMargin;
    double s = 1.0;
    if (outer > 0) {
      final double sx = (templateSize.width - 2 * outer) / templateSize.width;
      final double sy = (templateSize.height - 2 * outer) / templateSize.height;
      s = math.min(sx, sy);
    }
    final double marginX = (templateSize.width - templateSize.width * s) / 2;
    final double marginY = (templateSize.height - templateSize.height * s) / 2;

    double baseLeft = marginX + box.position.dx * s;
    double baseTop = marginY + box.position.dy * s;
    double baseWidth = box.size.width * s;
    double baseHeight = box.size.height * s;

    // Inner margin same as content (edge-aware)
    final double inner = collageManager.innerMargin;
    final double half = inner * 0.5;
    const double eps = 0.5;
    final bool isLeftEdge = box.position.dx <= eps;
    final bool isRightEdge = (box.position.dx + box.size.width) >= (templateSize.width - eps);
    final bool isTopEdge = box.position.dy <= eps;
    final bool isBottomEdge = (box.position.dy + box.size.height) >= (templateSize.height - eps);

    final double leftInset = isLeftEdge ? 0.0 : half;
    final double rightInset = isRightEdge ? 0.0 : half;
    final double topInset = isTopEdge ? 0.0 : half;
    final double bottomInset = isBottomEdge ? 0.0 : half;

    double adjustedLeft = baseLeft + leftInset;
    double adjustedTop = baseTop + topInset;
    double adjustedWidth = baseWidth - (leftInset + rightInset);
    double adjustedHeight = baseHeight - (topInset + bottomInset);

    final double dpr = MediaQuery.of(context).devicePixelRatio;
    double snap(double v) => (v * dpr).round() / dpr;
    adjustedLeft = snap(adjustedLeft);
    adjustedTop = snap(adjustedTop);
    adjustedWidth = snap(adjustedWidth);
    adjustedHeight = snap(adjustedHeight);

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
              size: 12.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.topLeft),
            ),

            // Top-right resize handle
            ResizeHandleWidget(
              box: box,
              alignment: Alignment.topRight,
              size: 12.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.topRight),
            ),

            // Bottom-left resize handle
            ResizeHandleWidget(
              box: box,
              alignment: Alignment.bottomLeft,
              size: 12.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.bottomLeft),
            ),

            // Bottom-right resize handle
            ResizeHandleWidget(
              box: box,
              alignment: Alignment.bottomRight,
              size: 12.0,
              onDrag: (dx, dy) =>
                  onResizeHandleDragged(box, dx, dy, Alignment.bottomRight),
            ),
          ],
        ),
      ),
    );
  }

  // Map angle to begin/end alignments (-1..1)
  Alignment _beginFromAngle(double deg) {
    final rad = deg * math.pi / 180.0;
    final dx = -math.cos(rad);
    final dy = -math.sin(rad);
    return Alignment(dx, dy);
  }

  Alignment _endFromAngle(double deg) {
    final rad = deg * math.pi / 180.0;
    final dx = math.cos(rad);
    final dy = math.sin(rad);
    return Alignment(dx, dy);
  }
}
