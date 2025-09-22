import 'package:flutter/material.dart';
import '../models/photo_box.dart';
import '../models/alignment_guideline.dart';
import '../widgets/photo_box_widget.dart';
import '../widgets/resize_handle_widget.dart';
import '../widgets/split_handle_widget.dart';
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
  // Callback to read current zoom scale from parent (InteractiveViewer)
  final double Function() getCurrentScale;
  // Notify parent when a box rotation gesture becomes active/inactive
  final void Function(bool active)? onRotateActive;

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
    required this.getCurrentScale,
    this.onRotateActive,
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
            begin: _beginFromAngle(collageManager.backgroundGradient.angleDeg),
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
      // Allow children (photo shadows, handles) to render into the padded
      // outer margin area without being clipped.
      clipBehavior: Clip.none,
      children: [
        for (var box in photoBoxes) _buildPhotoBox(box, context),
        if (selectedBox != null &&
            collageManager.isCustomMode &&
            photoBoxes.contains(selectedBox))
          _buildOverlay(selectedBox!, context),
        if (selectedBox != null)
          ..._buildSplitHandlesForSelected(selectedBox!, context),
        if (guidelines.isNotEmpty && collageManager.isCustomMode)
          GuidelinesOverlay(guidelines: guidelines, templateSize: templateSize),
      ],
    ),
  );

  /// Build individual photo box widget with inner/outer margins applied
  Widget _buildPhotoBox(PhotoBox box, BuildContext context) {
    // Map template coordinates into the padded inner area (equal px margin on all sides)
    final double outer = collageManager.outerMargin;
    final double innerW = templateSize.width - 2 * outer;
    final double innerH = templateSize.height - 2 * outer;
    final double sX = innerW / templateSize.width;
    final double sY = innerH / templateSize.height;

    double baseLeft = box.position.dx * sX;
    double baseTop = box.position.dy * sY;
    double baseWidth = box.size.width * sX;
    double baseHeight = box.size.height * sY;

    // Inner margin: apply only between photos (edge-aware), not on outer edges
    final double inner = collageManager.innerMargin;
    final double half = inner * 0.5;
    const double eps = 0.5; // edge tolerance in logical px
    final bool isLeftEdge = box.position.dx <= eps;
    final bool isRightEdge =
        (box.position.dx + box.size.width) >= (templateSize.width - eps);
    final bool isTopEdge = box.position.dy <= eps;
    final bool isBottomEdge =
        (box.position.dy + box.size.height) >= (templateSize.height - eps);

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
        child: Transform.rotate(
          alignment: Alignment.center,
          angle: box.rotationRadians,
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
            onRotateActive: onRotateActive,
          ),
        ),
      ),
    );
  }

  /// Build overlay for selected box with inner/outer margins applied
  Widget _buildOverlay(PhotoBox box, BuildContext context) {
    // Use same mapping as content: template -> padded inner area (equal px margins)
    final double outer = collageManager.outerMargin;
    final double innerW = templateSize.width - 2 * outer;
    final double innerH = templateSize.height - 2 * outer;
    final double sX = innerW / templateSize.width;
    final double sY = innerH / templateSize.height;

    double baseLeft = box.position.dx * sX;
    double baseTop = box.position.dy * sY;
    double baseWidth = box.size.width * sX;
    double baseHeight = box.size.height * sY;

    // Inner margin same as content (edge-aware)
    final double inner = collageManager.innerMargin;
    final double half = inner * 0.5;
    const double eps = 0.5;
    final bool isLeftEdge = box.position.dx <= eps;
    final bool isRightEdge =
        (box.position.dx + box.size.width) >= (templateSize.width - eps);
    final bool isTopEdge = box.position.dy <= eps;
    final bool isBottomEdge =
        (box.position.dy + box.size.height) >= (templateSize.height - eps);

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
        child: Transform.rotate(
          alignment: Alignment.center,
          angle: box.rotationRadians,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // GestureDetector deltas arrive in the box's local (unrotated) axes
              // because Transform.rotate already adjusts hit testing.
              // Top-left resize handle
              ResizeHandleWidget(
                box: box,
                alignment: Alignment.topLeft,
                size: 12.0,
                onDrag: (dx, dy) {
                  onResizeHandleDragged(
                    box,
                    dx,
                    dy,
                    Alignment.topLeft,
                  );
                },
              ),

              // Top-right resize handle
              ResizeHandleWidget(
                box: box,
                alignment: Alignment.topRight,
                size: 12.0,
                onDrag: (dx, dy) {
                  onResizeHandleDragged(
                    box,
                    dx,
                    dy,
                    Alignment.topRight,
                  );
                },
              ),

              // Bottom-left resize handle
              ResizeHandleWidget(
                box: box,
                alignment: Alignment.bottomLeft,
                size: 12.0,
                onDrag: (dx, dy) {
                  onResizeHandleDragged(
                    box,
                    dx,
                    dy,
                    Alignment.bottomLeft,
                  );
                },
              ),

              // Bottom-right resize handle
              ResizeHandleWidget(
                box: box,
                alignment: Alignment.bottomRight,
                size: 12.0,
                onDrag: (dx, dy) {
                  onResizeHandleDragged(
                    box,
                    dx,
                    dy,
                    Alignment.bottomRight,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build splitter handles for adjacent pairs that include the selected box
  List<Widget> _buildSplitHandlesForSelected(
    PhotoBox selected,
    BuildContext context,
  ) {
    final List<Widget> handles = [];

    final double outer = collageManager.outerMargin;
    final double innerW = templateSize.width - 2 * outer;
    final double innerH = templateSize.height - 2 * outer;
    final double sX = innerW / templateSize.width;
    final double sY = innerH / templateSize.height;

    final double eps = _edgeEps();

    // Build neighbor groups on each side of the selected box (with tolerant overlap)
    final leftNeighbors = _leftNeighborsFor(selected, eps);
    final rightNeighbors = _rightNeighborsFor(selected, eps);
    final topNeighbors = _topNeighborsFor(selected, eps);
    final bottomNeighbors = _bottomNeighborsFor(selected, eps);

    // Create handles for each non-empty group
    if (leftNeighbors.isNotEmpty) {
      final double x = selected.position.dx * sX;
      final double y = selected.position.dy * sY;
      final double h = selected.size.height * sY;
      handles.add(
        Positioned(
          left: x - 14,
          top: y,
          width: 28,
          height: h,
          child: SplitHandleWidget(
            isVertical: true,
            onDrag: (dxScreen) {
              final double scale = getCurrentScale();
              final double deltaTemplate = (dxScreen / scale) / sX;
              final double edgeX = selected.position.dx;
              final negativeGroup = _boxesWithRightEdgeAt(edgeX, eps);
              final positiveGroup = _boxesWithLeftEdgeAt(edgeX, eps);
              final applied = collageManager.resizeTwoGroupsAlongEdge(
                negativeGroup,
                positiveGroup,
                true,
                deltaTemplate,
              );
              // Snap all to the new divider line
              collageManager.snapGroupsToVerticalLine(
                negativeGroup,
                positiveGroup,
                edgeX + applied,
              );
            },
          ),
        ),
      );
    }

    if (rightNeighbors.isNotEmpty) {
      final double x = (selected.position.dx + selected.size.width) * sX;
      final double y = selected.position.dy * sY;
      final double h = selected.size.height * sY;
      handles.add(
        Positioned(
          left: x - 14,
          top: y,
          width: 28,
          height: h,
          child: SplitHandleWidget(
            isVertical: true,
            onDrag: (dxScreen) {
              final double scale = getCurrentScale();
              final double deltaTemplate = (dxScreen / scale) / sX;
              final double edgeX = selected.position.dx + selected.size.width;
              final negativeGroup = _boxesWithRightEdgeAt(edgeX, eps);
              final positiveGroup = _boxesWithLeftEdgeAt(edgeX, eps);
              final applied = collageManager.resizeTwoGroupsAlongEdge(
                negativeGroup,
                positiveGroup,
                true,
                deltaTemplate,
              );
              collageManager.snapGroupsToVerticalLine(
                negativeGroup,
                positiveGroup,
                edgeX + applied,
              );
            },
          ),
        ),
      );
    }

    if (topNeighbors.isNotEmpty) {
      final double x = selected.position.dx * sX;
      final double y = selected.position.dy * sY;
      final double w = selected.size.width * sX;
      handles.add(
        Positioned(
          left: x,
          top: y - 14,
          width: w,
          height: 28,
          child: SplitHandleWidget(
            isVertical: false,
            onDrag: (dyScreen) {
              final double scale = getCurrentScale();
              final double deltaTemplate = (dyScreen / scale) / sY;
              final double edgeY = selected.position.dy;
              final negativeGroup = _boxesWithBottomEdgeAt(edgeY, eps);
              final positiveGroup = _boxesWithTopEdgeAt(edgeY, eps);
              final applied = collageManager.resizeTwoGroupsAlongEdge(
                negativeGroup,
                positiveGroup,
                false,
                deltaTemplate,
              );
              collageManager.snapGroupsToHorizontalLine(
                negativeGroup,
                positiveGroup,
                edgeY + applied,
              );
            },
          ),
        ),
      );
    }

    if (bottomNeighbors.isNotEmpty) {
      final double x = selected.position.dx * sX;
      final double y = (selected.position.dy + selected.size.height) * sY;
      final double w = selected.size.width * sX;
      handles.add(
        Positioned(
          left: x,
          top: y - 14,
          width: w,
          height: 28,
          child: SplitHandleWidget(
            isVertical: false,
            onDrag: (dyScreen) {
              final double scale = getCurrentScale();
              final double deltaTemplate = (dyScreen / scale) / sY;
              final double edgeY = selected.position.dy + selected.size.height;
              final negativeGroup = _boxesWithBottomEdgeAt(edgeY, eps);
              final positiveGroup = _boxesWithTopEdgeAt(edgeY, eps);
              final applied = collageManager.resizeTwoGroupsAlongEdge(
                negativeGroup,
                positiveGroup,
                false,
                deltaTemplate,
              );
              collageManager.snapGroupsToHorizontalLine(
                negativeGroup,
                positiveGroup,
                edgeY + applied,
              );
            },
          ),
        ),
      );
    }

    return handles;
  }

  double _edgeEps() => math.max(3.0, collageManager.innerMargin * 0.5);

  bool _yOverlapEnough(PhotoBox a, PhotoBox b, double eps) {
    final double aTop = a.position.dy;
    final double aBottom = a.position.dy + a.size.height;
    final double bTop = b.position.dy;
    final double bBottom = b.position.dy + b.size.height;
    final double top = math.max(aTop, bTop);
    final double bottom = math.min(aBottom, bBottom);
    final double overlap = bottom - top;
    if (overlap <= 0) return false;
    final double minH = math.max(
      6.0,
      0.3 * math.min(a.size.height, b.size.height),
    );
    return overlap + eps >= minH;
  }

  bool _xOverlapEnough(PhotoBox a, PhotoBox b, double eps) {
    final double aLeft = a.position.dx;
    final double aRight = a.position.dx + a.size.width;
    final double bLeft = b.position.dx;
    final double bRight = b.position.dx + b.size.width;
    final double left = math.max(aLeft, bLeft);
    final double right = math.min(aRight, bRight);
    final double overlap = right - left;
    if (overlap <= 0) return false;
    final double minW = math.max(
      6.0,
      0.3 * math.min(a.size.width, b.size.width),
    );
    return overlap + eps >= minW;
  }

  List<PhotoBox> _leftNeighborsFor(PhotoBox selected, double eps) {
    final double selLeft = selected.position.dx;
    final res = <PhotoBox>[];
    for (final other in photoBoxes) {
      if (other == selected) continue;
      final double otherRight = other.position.dx + other.size.width;
      if ((otherRight - selLeft).abs() <= eps &&
          _yOverlapEnough(selected, other, eps)) {
        res.add(other);
      }
    }
    return res;
  }

  List<PhotoBox> _rightNeighborsFor(PhotoBox selected, double eps) {
    final double selRight = selected.position.dx + selected.size.width;
    final res = <PhotoBox>[];
    for (final other in photoBoxes) {
      if (other == selected) continue;
      if ((other.position.dx - selRight).abs() <= eps &&
          _yOverlapEnough(selected, other, eps)) {
        res.add(other);
      }
    }
    return res;
  }

  List<PhotoBox> _topNeighborsFor(PhotoBox selected, double eps) {
    final double selTop = selected.position.dy;
    final res = <PhotoBox>[];
    for (final other in photoBoxes) {
      if (other == selected) continue;
      final double otherBottom = other.position.dy + other.size.height;
      if ((otherBottom - selTop).abs() <= eps &&
          _xOverlapEnough(selected, other, eps)) {
        res.add(other);
      }
    }
    return res;
  }

  List<PhotoBox> _bottomNeighborsFor(PhotoBox selected, double eps) {
    final double selBottom = selected.position.dy + selected.size.height;
    final res = <PhotoBox>[];
    for (final other in photoBoxes) {
      if (other == selected) continue;
      if ((other.position.dy - selBottom).abs() <= eps &&
          _xOverlapEnough(selected, other, eps)) {
        res.add(other);
      }
    }
    return res;
  }

  // Edge-based group helpers filtered by overlap with selected's span
  List<PhotoBox> _boxesWithRightEdgeAt(double x, double eps) {
    final res = <PhotoBox>[];
    for (final b in photoBoxes) {
      final double right = b.position.dx + b.size.width;
      if ((right - x).abs() <= eps) {
        res.add(b);
      }
    }
    return res;
  }

  List<PhotoBox> _boxesWithLeftEdgeAt(double x, double eps) {
    final res = <PhotoBox>[];
    for (final b in photoBoxes) {
      if ((b.position.dx - x).abs() <= eps) {
        res.add(b);
      }
    }
    return res;
  }

  List<PhotoBox> _boxesWithBottomEdgeAt(double y, double eps) {
    final res = <PhotoBox>[];
    for (final b in photoBoxes) {
      final double bottom = b.position.dy + b.size.height;
      if ((bottom - y).abs() <= eps) {
        res.add(b);
      }
    }
    return res;
  }

  List<PhotoBox> _boxesWithTopEdgeAt(double y, double eps) {
    final res = <PhotoBox>[];
    for (final b in photoBoxes) {
      if ((b.position.dy - y).abs() <= eps) {
        res.add(b);
      }
    }
    return res;
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
